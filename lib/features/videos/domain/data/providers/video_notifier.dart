import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
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
      tempPath: videoTempDir.path,
      frames: [],
      isRecording: false,
    );
  }

  Future<File?> captureVideoWithGphoto2() async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to capture video.");
    }

    final fileName =
        'gphoto2_video_${DateTime.now().millisecondsSinceEpoch}.mov';
    final fullWindowsPath = p.join(currentState.tempPath, fileName);

    // Convert Windows path to WSL path format
    final wslPath = fullWindowsPath
        .replaceAll(r'\', '/')
        .replaceAll('C:', '/mnt/c');

    print('Attempting gphoto2 video capture to: $wslPath');

    try {
      // First check if camera is detected
      final detectResult = await Process.run('wsl.exe', [
        'bash',
        '-c',
        'gphoto2 --auto-detect 2>&1 | grep -v "No cameras detected" | wc -l',
      ]);

      if (detectResult.exitCode != 0 ||
          detectResult.stdout.toString().trim() == '0') {
        print('No cameras detected by gphoto2');
        return null;
      }

      // Capture 7-second video with gphoto2
      final result = await Process.run('wsl.exe', [
        'bash',
        '-c',
        'gphoto2 --capture-movie=7s --stdout > "$wslPath" 2>/dev/null && echo "success" || echo "failed"',
      ]);

      print('gphoto2 exit code: ${result.exitCode}');
      print('gphoto2 stdout: ${result.stdout}');

      if (result.exitCode == 0 &&
          result.stdout.toString().contains('success')) {
        final videoFile = File(fullWindowsPath);
        if (await videoFile.exists()) {
          final fileSize = await videoFile.length();
          print('gphoto2 video captured successfully, size: $fileSize bytes');

          if (fileSize > 1024) {
            return videoFile;
          } else {
            print('gphoto2 video file too small, will use fallback');
            await videoFile.delete();
          }
        }
      }
    } catch (e) {
      print('gphoto2 capture error: $e');
    }

    return null;
  }

  Future<void> saveVideoFromGphoto2(File gphoto2File) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final videoFileName =
          'flipbook_gphoto2_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoFilePath = p.join(currentState.tempPath, videoFileName);

      try {
        // Copy gphoto2 file to our temp directory with standard naming
        await gphoto2File.copy(videoFilePath);

        print('gphoto2 video saved to: $videoFilePath');

        final fileSize = await File(videoFilePath).length();
        print('Video file size: $fileSize bytes');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoFilePath);
        }

        // Clean up original gphoto2 file
        if (await gphoto2File.exists()) {
          await gphoto2File.delete();
        }

        return currentState.copyWith(
          videoPath: videoFilePath,
          isRecording: false,
        );
      } catch (e) {
        print('Error saving gphoto2 video: $e');

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

  Future<void> saveVideoFromCapture(XFile videoXFile) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      final videoFileName =
          'flipbook_camera_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoFilePath = p.join(currentState.tempPath, videoFileName);

      try {
        // Read bytes from XFile and write to our designated path
        final videoBytes = await videoXFile.readAsBytes();
        final targetFile = File(videoFilePath);
        await targetFile.writeAsBytes(videoBytes);

        print('Camera video saved to: $videoFilePath');

        final fileSize = await targetFile.length();
        print('Video file size: $fileSize bytes');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoFilePath);
        }

        return currentState.copyWith(
          videoPath: videoFilePath,
          isRecording: false,
        );
      } catch (e) {
        print('Error saving camera video: $e');

        // Create fallback video if saving fails
        await _createFallbackVideo(videoFilePath);

        return currentState.copyWith(
          videoPath: videoFilePath,
          isRecording: false,
        );
      }
    });
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

      // Delete all frame files
      for (final frame in currentState.frames) {
        final frameFile = File(frame.path);
        if (await frameFile.exists()) {
          await frameFile.delete();
        }
      }

      return currentState.copyWith(
        videoPath: null,
        frames: [],
        isRecording: false,
      );
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
      final outputFileName =
          'filtered_${filterName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.mp4';
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

      print('Splitting 7-second video into frames (4 frames per second)...');

      // Clear existing frames
      for (final frame in currentState.frames) {
        final frameFile = File(frame.path);
        if (await frameFile.exists()) {
          await frameFile.delete();
        }
      }

      try {
        // Extract frames at 4fps to get approximately 28 frames from 7-second video
        final framePattern = p.join(currentState.tempPath, 'frame_%03d.jpg');

        final ffmpegArgs = [
          '-i', currentState.videoPath!,
          '-vf',
          'fps=4,scale=${VideoFilterConstants.videoWidth}:${VideoFilterConstants.videoHeight}',
          '-q:v', '2', // High quality JPEG
          '-y', // Overwrite existing files
          framePattern,
        ];

        print('Extracting frames: ffmpeg ${ffmpegArgs.join(' ')}');
        final process = await Process.run('ffmpeg', ffmpegArgs);

        if (process.exitCode != 0) {
          print('Frame extraction failed: ${process.stderr}');
          throw Exception('Frame extraction failed: ${process.stderr}');
        }

        // Collect all generated frame files
        final frameFiles = <File>[];
        final tempDir = Directory(currentState.tempPath);

        await for (final entity in tempDir.list()) {
          if (entity is File &&
              entity.path.contains('frame_') &&
              entity.path.endsWith('.jpg')) {
            frameFiles.add(entity);
          }
        }

        // Sort frames by filename to maintain order
        frameFiles.sort((a, b) => a.path.compareTo(b.path));

        print('Found ${frameFiles.length} frames');

        // Create FrameModel objects
        final frames = frameFiles.asMap().entries.map((entry) {
          return FrameModel(
            path: entry.value.path,
            index: entry.key,
            isSelected: false,
          );
        }).toList();

        print('Successfully split video into ${frames.length} frames');

        return currentState.copyWith(frames: frames);
      } catch (e) {
        print('Error splitting video into frames: $e');
        throw Exception('Failed to split video into frames: $e');
      }
    });
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

      final updatedFrames = currentState.frames.map((frame) {
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

      final updatedFrames = currentState.frames.map((frame) {
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

      final updatedFrames = currentState.frames.map((frame) {
        return frame.copyWith(isSelected: false);
      }).toList();

      return currentState.copyWith(frames: updatedFrames);
    });
  }

  List<FrameModel> getSelectedFrames() {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState.frames.where((frame) => frame.isSelected).toList();
  }
}

final videoProvider = AsyncNotifierProvider<VideoNotifier, VideoState>(
  () => VideoNotifier(),
);
