import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/video_state.dart';
import 'package:photocafe_windows/features/videos/domain/data/constants/filter_constants.dart';

class VideoNotifier extends AsyncNotifier<VideoState> {
  Process? _ffmpegProcess;
  MediaRecorder? _mediaRecorder;
  MediaStream? _recordingStream;

  @override
  Future<VideoState> build() async {
    final tempPath = await getTemporaryDirectory();
    final videoTempDir = Directory(p.join(tempPath.path, 'videos'));

    if (!await videoTempDir.exists()) {
      await videoTempDir.create(recursive: true);
    }

    return VideoState(
      videoPath: null,
      tempPath: videoTempDir.path,
      frames: [],
      isRecording: false,
    );
  }

  Future<void> startRecording(MediaStream stream) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      print('Starting MediaRecorder for flipbook recording...');

      _recordingStream = stream;
      _mediaRecorder = MediaRecorder();

      // Generate output path
      final videoFileName =
          'flipbook_recording_${DateTime.now().millisecondsSinceEpoch}.webm';
      final outputPath = p.join(currentState.tempPath, videoFileName);

      await _mediaRecorder!.start(
        outputPath,
        videoTrack: stream.getVideoTracks().first,
      );

      return currentState.copyWith(isRecording: true);
    });
  }

  Future<void> stopRecording() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null || _mediaRecorder == null) {
        throw Exception('No recording to stop');
      }

      print('Stopping MediaRecorder...');

      final recordedPath = await _mediaRecorder!.stop();
      _mediaRecorder = null;
      _recordingStream = null;

      print('Recording saved to: $recordedPath');

      // Convert webm to mp4 for compatibility
      final mp4Path = await _convertToMp4(recordedPath);

      return currentState.copyWith(videoPath: mp4Path, isRecording: false);
    });
  }

  Future<String> _convertToMp4(String webmPath) async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception('Video state is not initialized');
    }

    final outputFileName =
        'flipbook_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final outputPath = p.join(currentState.tempPath, outputFileName);

    try {
      print('Converting webm to mp4: $webmPath -> $outputPath');

      final ffmpegArgs = [
        '-i', webmPath,
        '-c:v', 'libx264',
        '-c:a', 'aac',
        '-movflags', '+faststart',
        '-y', // Overwrite output
        outputPath,
      ];

      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        // Clean up original webm file
        final webmFile = File(webmPath);
        if (await webmFile.exists()) {
          await webmFile.delete();
        }

        print('Successfully converted to mp4: $outputPath');
        return outputPath;
      } else {
        print('FFmpeg conversion failed: ${process.stderr}');
        // Return original webm if conversion fails
        return webmPath;
      }
    } catch (e) {
      print('Error converting to mp4: $e');
      // Return original webm if conversion fails
      return webmPath;
    }
  }

  Future<void> saveVideoFromPhotoCamera(String videoPath) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      try {
        print('Saving video from photo camera: $videoPath');

        final fileSize = await File(videoPath).length();
        print('Video file size: $fileSize bytes');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoPath);
        }

        return currentState.copyWith(videoPath: videoPath, isRecording: false);
      } catch (e) {
        print('Error saving photo camera video: $e');
        // Create fallback video if saving fails
        await _createFallbackVideo(videoPath);

        return currentState.copyWith(videoPath: videoPath, isRecording: false);
      }
    });
  }

  Future<void> _createFallbackVideo(String outputPath) async {
    try {
      print('Creating 7-second fallback video at: $outputPath');

      // Ensure the directory exists
      final outputDir = Directory(p.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final ffmpegArgs = [
        '-f', 'lavfi',
        '-i',
        'testsrc=duration=7:size=${VideoFilterConstants.videoWidth}x${VideoFilterConstants.videoHeight}:rate=25',
        '-f', 'lavfi',
        '-i', 'sine=frequency=1000:duration=7',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-shortest',
        '-y', // Overwrite output file
        outputPath,
      ];

      print('Running FFmpeg fallback: ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          print(
            '7-second fallback video created successfully, size: $fileSize bytes',
          );
        }
      } else {
        print('Fallback video creation failed: ${process.stderr}');
      }
    } catch (e) {
      print('Error creating fallback video: $e');
    }
  }

  Future<void> clearVideo() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) return state.value!;

      // Delete video file if exists
      if (currentState.videoPath != null) {
        final videoFile = File(currentState.videoPath!);
        if (await videoFile.exists()) {
          await videoFile.delete();
        }
      }

      // Delete all frame files and frame directories
      for (final frame in currentState.frames) {
        final frameFile = File(frame.path);
        if (await frameFile.exists()) {
          await frameFile.delete();
        }
      }

      // Clean up any existing frame directories
      final tempDir = Directory(currentState.tempPath);
      await for (final entity in tempDir.list()) {
        if (entity is Directory && entity.path.contains('frames_')) {
          try {
            await entity.delete(recursive: true);
            print('Cleaned up frame directory: ${entity.path}');
          } catch (e) {
            print('Error cleaning up frame directory: $e');
          }
        }
      }

      return currentState.copyWith(
        videoPath: null,
        frames: [],
        isRecording: false,
      );
    });
  }

  Future<void> splitVideoIntoFrames() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null || currentState.videoPath == null) {
        throw Exception('No video available for frame splitting');
      }

      final videoFile = File(currentState.videoPath!);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found at: ${currentState.videoPath}');
      }

      print('Splitting 7-second video into 50 frames for 50-page flipbook...');

      // Create a unique frame directory for this video session
      final sessionId = DateTime.now().millisecondsSinceEpoch;
      final frameDir = Directory(
        p.join(currentState.tempPath, 'frames_$sessionId'),
      );

      if (!await frameDir.exists()) {
        await frameDir.create(recursive: true);
      }

      // Clear existing frames from state
      for (final frame in currentState.frames) {
        final frameFile = File(frame.path);
        if (await frameFile.exists()) {
          await frameFile.delete();
        }
      }

      try {
        // Extract 50 frames from 7-second video (50/7 ≈ 7.14 fps)
        final framePattern = p.join(frameDir.path, 'frame_%03d.jpg');

        final ffmpegArgs = [
          '-i', currentState.videoPath!,
          '-vf',
          'fps=50/7,scale=${VideoFilterConstants.videoWidth}:${VideoFilterConstants.videoHeight}',
          '-frames:v', '50', // Explicitly limit to 50 frames
          '-q:v', '2', // High quality JPEG
          '-y', // Overwrite existing files
          framePattern,
        ];

        print('Extracting 50 frames: ffmpeg ${ffmpegArgs.join(' ')}');
        final process = await Process.run('ffmpeg', ffmpegArgs);

        if (process.exitCode != 0) {
          print('Frame extraction failed: ${process.stderr}');
          throw Exception('Frame extraction failed: ${process.stderr}');
        }

        // Collect all generated frame files from the session directory
        final frameFiles = <File>[];
        await for (final entity in frameDir.list()) {
          if (entity is File &&
              entity.path.contains('frame_') &&
              entity.path.endsWith('.jpg')) {
            frameFiles.add(entity);
          }
        }

        // Sort frames by filename to maintain order
        frameFiles.sort((a, b) => a.path.compareTo(b.path));

        print('Found ${frameFiles.length} frames in session directory');

        // Ensure we have exactly 50 frames
        if (frameFiles.length < 50) {
          print(
            'Warning: Only ${frameFiles.length} frames extracted, expected 50',
          );
        } else if (frameFiles.length > 50) {
          print('Trimming to exactly 50 frames');
          frameFiles.removeRange(50, frameFiles.length);
        }

        // Create FrameModel objects
        final frames = frameFiles.asMap().entries.map((entry) {
          return FrameModel(
            path: entry.value.path,
            index: entry.key,
            isSelected: false,
          );
        }).toList();

        print(
          'Successfully split video into ${frames.length} frames for flipbook',
        );
        print('Frames stored in: ${frameDir.path}');

        return currentState.copyWith(frames: frames);
      } catch (e) {
        print('Error splitting video into frames: $e');

        // Clean up the frame directory on error
        if (await frameDir.exists()) {
          try {
            await frameDir.delete(recursive: true);
          } catch (cleanupError) {
            print('Error cleaning up frame directory: $cleanupError');
          }
        }

        throw Exception('Failed to split video into frames: $e');
      }
    });
  }

  Future<String?> applyVideoFilter(String filterName) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null || currentState.videoPath == null) {
        throw Exception('No video available for filter processing');
      }

      final videoFile = File(currentState.videoPath!);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found at: ${currentState.videoPath}');
      }

      // Create output path for filtered video
      final sessionId = DateTime.now().millisecondsSinceEpoch;
      final outputFileName =
          'filtered_${filterName.replaceAll(' ', '_').toLowerCase()}_$sessionId.mp4';
      final outputPath = p.join(currentState.tempPath, outputFileName);

      try {
        print('Applying filter "$filterName" to video...');
        print('Input: ${currentState.videoPath}');
        print('Output: $outputPath');

        final filterArgs = VideoFilterConstants.getFilterArgs(filterName);

        final ffmpegArgs = [
          '-i', currentState.videoPath!,
          '-y', // Overwrite output
          '-v', 'info',
        ];

        // Add video filters if any
        if (filterArgs.isNotEmpty) {
          ffmpegArgs.addAll(['-vf', filterArgs.join(',')]);
        }

        ffmpegArgs.addAll([
          '-c:v',
          'libx264',
          '-preset',
          'fast',
          '-crf',
          '23',
          '-movflags',
          '+faststart',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          outputPath,
        ]);

        print('Running FFmpeg: ffmpeg ${ffmpegArgs.join(' ')}');
        final process = await Process.run('ffmpeg', ffmpegArgs);

        if (process.exitCode == 0) {
          final outputFile = File(outputPath);
          if (await outputFile.exists()) {
            final fileSize = await outputFile.length();
            print('Filter applied successfully, size: $fileSize bytes');

            // Clean up old video file if it's different from the new one
            if (currentState.videoPath != outputPath) {
              try {
                await File(currentState.videoPath!).delete();
                print('Cleaned up old video file: ${currentState.videoPath}');
              } catch (e) {
                print('Warning: Could not clean up old video file: $e');
              }
            }

            return currentState.copyWith(videoPath: outputPath);
          }
        } else {
          print('Filter application failed: ${process.stderr}');
          throw Exception('Filter application failed: ${process.stderr}');
        }
      } catch (e) {
        print('Error applying filter: $e');
        throw Exception('Failed to apply filter: $e');
      }

      return currentState;
    });

    return state.value?.videoPath;
  }

  Future<void> processVideoWithFilter(String filterName) async {
    try {
      print('Starting video processing with filter: $filterName');

      // Step 1: Apply filter to video
      final filteredVideoPath = await applyVideoFilter(filterName);

      if (filteredVideoPath != null) {
        print('Filter applied successfully, now splitting into frames...');

        // Step 2: Split filtered video into frames
        await splitVideoIntoFrames();

        print('Video processing completed successfully');
      } else {
        throw Exception('Failed to apply filter to video');
      }
    } catch (e) {
      print('Error in video processing: $e');

      // Update state with error
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> selectFrame(int index) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final updatedFrames = currentState.frames.map<FrameModel>((frame) {
        if (frame.index == index) {
          return frame.copyWith(isSelected: !frame.isSelected);
        }
        return frame;
      }).toList();

      return currentState.copyWith(frames: updatedFrames);
    });
  }

  Future<void> selectAllFrames() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final updatedFrames = currentState.frames.map<FrameModel>((frame) {
        return frame.copyWith(isSelected: true);
      }).toList();

      return currentState.copyWith(frames: updatedFrames);
    });
  }

  Future<void> deselectAllFrames() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final updatedFrames = currentState.frames.map<FrameModel>((frame) {
        return frame.copyWith(isSelected: false);
      }).toList();

      return currentState.copyWith(frames: updatedFrames);
    });
  }

  List<FrameModel> getSelectedFrames() {
    final currentState = state.value;
    if (currentState == null) return <FrameModel>[];

    return currentState.frames.where((frame) => frame.isSelected).toList();
  }
}

final videoProvider = AsyncNotifierProvider<VideoNotifier, VideoState>(
  () => VideoNotifier(),
);
