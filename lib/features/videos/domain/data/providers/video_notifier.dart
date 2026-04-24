import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/video_state.dart';
import 'package:photocafe_windows/features/videos/domain/data/constants/filter_constants.dart';

class VideoNotifier extends AsyncNotifier<VideoState> {
  Process? _ffmpegProcess;

  @override
  Future<VideoState> build() async {
    final tempPath = await getTemporaryDirectory();
    final videoTempDir = Directory(p.join(tempPath.path, 'videos'));

    if (!await videoTempDir.exists()) {
      await videoTempDir.create(recursive: true);
    }

    return VideoState(
      videoPath: null,
      videoTakes: [], // Initialize empty takes list
      selectedTakeIndex: null,
      tempPath: videoTempDir.path,
      frames: [],
      isRecording: false,
    );
  }

  /// Save a video take from a Canon EDSDK preview recording AVI file path.
  /// Moves (not copies) the source file to avoid doubling disk usage.
  Future<void> saveVideoTake(String sourceVideoPath) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final takeNumber = currentState.videoTakes.length + 1;
      final videoFileName =
          'flipbook_take_${takeNumber}_${DateTime.now().millisecondsSinceEpoch}.avi';
      final videoFilePath = p.join(currentState.tempPath, videoFileName);

      try {
        final sourceFile = File(sourceVideoPath);
        final fileSize = await sourceFile.length();
        print('Take $takeNumber source: $sourceVideoPath ($fileSize bytes)');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoFilePath);
        } else {
          // Move instead of copy to save disk space.
          // rename() works if same volume; falls back to copy+delete.
          try {
            await sourceFile.rename(videoFilePath);
          } catch (_) {
            await sourceFile.copy(videoFilePath);
            await sourceFile.delete();
          }
          print('Take $takeNumber stored at: $videoFilePath');
        }

        // Add to takes list
        final updatedTakes = List<String>.from(currentState.videoTakes)
          ..add(videoFilePath);

        return currentState.copyWith(
          videoTakes: updatedTakes,
          videoPath: videoFilePath, // Set as current active video
          isRecording: false,
        );
      } catch (e) {
        print('Error saving take: $e');
        await _createFallbackVideo(videoFilePath);

        final updatedTakes = List<String>.from(currentState.videoTakes)
          ..add(videoFilePath);

        return currentState.copyWith(
          videoTakes: updatedTakes,
          videoPath: videoFilePath,
          isRecording: false,
        );
      }
    });
  }

  Future<void> selectTake(int index) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      if (index < 0 || index >= currentState.videoTakes.length) {
        throw Exception('Invalid take index');
      }

      final selectedVideoPath = currentState.videoTakes[index];

      return currentState.copyWith(
        selectedTakeIndex: index,
        videoPath: selectedVideoPath, // Set as active video
      );
    });
  }

  /// Save a video from a Canon EDSDK preview recording AVI file path.
  /// Moves (not copies) the source file to avoid doubling disk usage.
  Future<void> saveVideoFromCanon(String sourceVideoPath) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final videoFileName =
          'flipbook_canon_${DateTime.now().millisecondsSinceEpoch}.avi';
      final videoFilePath = p.join(currentState.tempPath, videoFileName);

      try {
        final sourceFile = File(sourceVideoPath);
        final fileSize = await sourceFile.length();
        print('Canon video source: $sourceVideoPath ($fileSize bytes)');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoFilePath);
        } else {
          // Move instead of copy to save disk space
          try {
            await sourceFile.rename(videoFilePath);
          } catch (_) {
            await sourceFile.copy(videoFilePath);
            await sourceFile.delete();
          }
          print('Canon video stored at: $videoFilePath');
        }

        return currentState.copyWith(
          videoPath: videoFilePath,
          isRecording: false,
        );
      } catch (e) {
        print('Error saving Canon video: $e');

        // Create fallback video if saving fails
        await _createFallbackVideo(videoFilePath);

        return currentState.copyWith(
          videoPath: videoFilePath,
          isRecording: false,
        );
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

      // Delete all video takes
      for (final takePath in currentState.videoTakes) {
        final videoFile = File(takePath);
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
        videoTakes: [],
        selectedTakeIndex: null,
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
        // Extract exactly 50 frames evenly distributed from 7-second video
        // 50 frames / 7 seconds ≈ 7.14 fps
        final framePattern = p.join(frameDir.path, 'frame_%03d.jpg');

        final ffmpegArgs = [
          '-i', currentState.videoPath!,
          '-v', 'warning', // Reduce log verbosity for speed
          '-threads', '0', // Use all available CPU threads
          '-vf',
          'fps=7.142857,scale=${VideoFilterConstants.videoWidth}:${VideoFilterConstants.videoHeight}',
          '-frames:v', '50', // Extract exactly 50 frames
          '-q:v', '3', // Slightly lower quality for faster extraction (was 2)
          '-y',
          framePattern,
        ];

        print('Extracting 50 frames: ffmpeg ${ffmpegArgs.join(' ')}');
        final process = await Process.run('ffmpeg', ffmpegArgs);

        if (process.exitCode != 0) {
          print('Frame extraction failed: ${process.stderr}');
          throw Exception('Frame extraction failed: ${process.stderr}');
        }

        final frameFiles = <File>[];
        await for (final entity in frameDir.list()) {
          if (entity is File &&
              entity.path.contains('frame_') &&
              entity.path.endsWith('.jpg')) {
            frameFiles.add(entity);
          }
        }

        frameFiles.sort((a, b) => a.path.compareTo(b.path));

        print('Found ${frameFiles.length} frames in session directory');

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
          '-v', 'warning', // Reduce log verbosity for speed
          '-threads', '0', // Use all available CPU threads
        ];

        // Add video filters if any
        if (filterArgs.isNotEmpty) {
          ffmpegArgs.addAll(['-vf', filterArgs.join(',')]);
        }

        // Optimized encoding settings for faster processing
        ffmpegArgs.addAll([
          '-threads', '0', // Use all available CPU threads
          '-c:v', 'libx264',
          '-preset', 'veryfast', // Faster preset (was 'fast')
          '-tune', 'fastdecode',
          '-crf', '25', // Slightly lower quality for faster encoding
          '-movflags', '+faststart',
          '-c:a', 'aac',
          '-b:a', '96k', // Lower bitrate for faster encoding
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

  Future<void> removeLastTake() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      if (currentState.videoTakes.isEmpty) {
        print('No takes to remove');
        return currentState;
      }

      // Get the last take path
      final lastTakePath = currentState.videoTakes.last;

      // Delete the file
      final file = File(lastTakePath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted take file: $lastTakePath');
      }

      // Remove from takes list
      final updatedTakes = List<String>.from(currentState.videoTakes)
        ..removeLast();

      // Update videoPath to the new last take, or null if no takes left
      final newVideoPath = updatedTakes.isNotEmpty ? updatedTakes.last : null;

      print('Removed last take. Remaining takes: ${updatedTakes.length}');

      return currentState.copyWith(
        videoTakes: updatedTakes,
        videoPath: newVideoPath,
        selectedTakeIndex: null, // Clear selection after removing a take
      );
    });
  }

  Future<String?> applyVideoFilterForPreview(String filterName) async {
    final currentState = state.value;
    if (currentState == null || currentState.videoPath == null) {
      throw Exception('No video available for filter processing');
    }

    final videoFile = File(currentState.videoPath!);
    if (!await videoFile.exists()) {
      throw Exception('Video file not found at: ${currentState.videoPath}');
    }

    // Create output path for preview filtered video
    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final outputFileName =
        'preview_${filterName.replaceAll(' ', '_').toLowerCase()}_$sessionId.mp4';
    final outputPath = p.join(currentState.tempPath, outputFileName);

    try {
      print('Applying preview filter "$filterName" to video...');
      print('Input: ${currentState.videoPath}');
      print('Output: $outputPath');

      final filterArgs = VideoFilterConstants.getFilterArgs(filterName);

      final ffmpegArgs = [
        '-i', currentState.videoPath!,
        '-y', // Overwrite output
        '-v', 'warning', // Reduce log verbosity for speed
        '-threads', '0', // Use all available CPU threads
      ];

      // Add video filters if any
      if (filterArgs.isNotEmpty) {
        ffmpegArgs.addAll(['-vf', filterArgs.join(',')]);
      }

      // Add codec and format settings with explicit pixel format for compatibility
      ffmpegArgs.addAll([
        '-c:v', 'libx264',
        '-preset', 'ultrafast', // Fastest for preview
        '-tune', 'fastdecode', // Optimize for fast decoding
        '-crf', '26', // Slightly lower quality for faster encoding
        '-pix_fmt', 'yuv420p', // Explicit pixel format for better compatibility
        '-profile:v',
        'baseline', // Use baseline profile for better compatibility
        '-level', '3.0', // Compatibility level
        '-movflags', '+faststart',
        '-c:a', 'copy', // Copy audio instead of re-encoding for speed
        outputPath,
      ]);

      print('Running FFmpeg preview: ffmpeg ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          print('Preview filter applied successfully, size: $fileSize bytes');

          // Verify the output file is valid
          if (fileSize < 1024) {
            print('Warning: Preview file is too small, may be corrupted');
            return null;
          }

          return outputPath;
        }
      } else {
        print('Preview filter application failed: ${process.stderr}');
        return null;
      }
    } catch (e) {
      print('Error applying preview filter: $e');
      return null;
    }

    return null;
  }

  /// Load an externally-provided video (e.g. uploaded by the user via the web
  /// upload page) into the video pipeline so it can be processed through
  /// filters, frame extraction, and PDF generation just like a Canon recording.
  Future<void> loadExternalVideo(String localVideoPath) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final videoFile = File(localVideoPath);
      if (!await videoFile.exists()) {
        throw Exception('External video file not found: $localVideoPath');
      }

      // Clear any previous takes / frames
      for (final takePath in currentState.videoTakes) {
        final f = File(takePath);
        if (await f.exists()) await f.delete();
      }
      for (final frame in currentState.frames) {
        final f = File(frame.path);
        if (await f.exists()) await f.delete();
      }

      return currentState.copyWith(
        videoPath: localVideoPath,
        videoTakes: [localVideoPath],
        selectedTakeIndex: 0,
        frames: [],
        isRecording: false,
        error: null,
      );
    });
  }
}

final videoProvider = AsyncNotifierProvider<VideoNotifier, VideoState>(
  () => VideoNotifier(),
);
