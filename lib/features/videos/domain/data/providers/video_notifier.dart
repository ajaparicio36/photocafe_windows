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

    final mjpegFileName =
        'gphoto2_video_${DateTime.now().millisecondsSinceEpoch}.mjpg';
    final fullWindowsPath = p.join(currentState.tempPath, mjpegFileName);

    // Convert Windows path to WSL path format
    final wslPath = fullWindowsPath
        .replaceAll(r'\', '/')
        .replaceAll('C:', '/mnt/c');

    print('Attempting gphoto2 video capture to: $wslPath');

    try {
      // Reset camera and ensure no processes are using it
      await _resetGphoto2Camera();

      // Wait a moment for camera to be ready
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check camera with more detailed detection
      final isReady = await _checkCameraReady();
      if (!isReady) {
        print('Camera not ready for gphoto2 capture');
        return null;
      }

      // Try capture with retries - now captures MJPEG
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('gphoto2 capture attempt $attempt/3');

        final result = await Process.run('wsl.exe', [
          'bash',
          '-c',
          'timeout 15s gphoto2 --capture-movie=7s --stdout > "$wslPath" 2>/dev/null && echo "success" || echo "failed"',
        ]);

        print('gphoto2 attempt $attempt - exit code: ${result.exitCode}');
        print('gphoto2 attempt $attempt - output: ${result.stdout}');

        if (result.exitCode == 0 &&
            result.stdout.toString().contains('success')) {
          final mjpegFile = File(fullWindowsPath);
          if (await mjpegFile.exists()) {
            final fileSize = await mjpegFile.length();
            print('gphoto2 MJPEG captured successfully, size: $fileSize bytes');

            if (fileSize > 1024) {
              // Convert MJPEG to MP4 before returning
              final mp4File = await _convertMjpegToMp4(mjpegFile);
              return mp4File;
            } else {
              print('gphoto2 MJPEG file too small, deleting and retrying...');
              await mjpegFile.delete();
            }
          }
        }

        // If failed and not last attempt, reset camera and wait
        if (attempt < 3) {
          print('gphoto2 capture failed, resetting camera for retry...');
          await _resetGphoto2Camera();
          await Future.delayed(const Duration(milliseconds: 2000));
        }
      }

      print('All gphoto2 capture attempts failed, will use fallback');
    } catch (e) {
      print('gphoto2 capture error: $e');
    }

    return null;
  }

  Future<File?> _convertMjpegToMp4(File mjpegFile) async {
    final currentState = state.value;
    if (currentState == null) {
      print('State not available for MJPEG conversion');
      return null;
    }

    final mp4FileName = mjpegFile.path.replaceAll('.mjpg', '.mp4');

    try {
      print('Converting MJPEG to MP4...');
      print('Input: ${mjpegFile.path}');
      print('Output: $mp4FileName');

      final ffmpegArgs = [
        '-i', mjpegFile.path,
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart',
        '-an', // No audio since MJPEG doesn't have audio
        '-y', // Overwrite output
        mp4FileName,
      ];

      print('Running FFmpeg: ffmpeg ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final mp4File = File(mp4FileName);
        if (await mp4File.exists()) {
          final fileSize = await mp4File.length();
          print('MJPEG to MP4 conversion successful, size: $fileSize bytes');

          // Clean up the original MJPEG file
          if (await mjpegFile.exists()) {
            await mjpegFile.delete();
          }

          return mp4File;
        }
      } else {
        print('MJPEG to MP4 conversion failed: ${process.stderr}');
      }
    } catch (e) {
      print('Error converting MJPEG to MP4: $e');
    }

    // If conversion failed, clean up MJPEG file and return null
    if (await mjpegFile.exists()) {
      await mjpegFile.delete();
    }

    return null;
  }

  Future<void> saveVideoFromGphoto2(File gphoto2File) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception('Video state is not initialized');
      }

      // The gphoto2File should already be the converted MP4 file
      final videoFileName =
          'flipbook_gphoto2_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoFilePath = p.join(currentState.tempPath, videoFileName);

      try {
        // Copy converted MP4 file to our temp directory with standard naming
        await gphoto2File.copy(videoFilePath);

        print('gphoto2 converted video saved to: $videoFilePath');

        final fileSize = await File(videoFilePath).length();
        print('Final video file size: $fileSize bytes');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoFilePath);
        }

        // Clean up original converted file only if it's different from final path
        if (gphoto2File.path != videoFilePath && await gphoto2File.exists()) {
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

      print('Splitting 7-second video into 100 frames for 50-page flipbook...');

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
        // Extract 100 frames from 7-second video (100/7 ≈ 14.3 fps)
        final framePattern = p.join(frameDir.path, 'frame_%03d.jpg');

        final ffmpegArgs = [
          '-i', currentState.videoPath!,
          '-vf',
          'fps=100/7,scale=${VideoFilterConstants.videoWidth}:${VideoFilterConstants.videoHeight}',
          '-frames:v', '100', // Explicitly limit to 100 frames
          '-q:v', '2', // High quality JPEG
          '-y', // Overwrite existing files
          framePattern,
        ];

        print('Extracting 100 frames: ffmpeg ${ffmpegArgs.join(' ')}');
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

        // Ensure we have exactly 100 frames
        if (frameFiles.length < 100) {
          print(
            'Warning: Only ${frameFiles.length} frames extracted, expected 100',
          );
        } else if (frameFiles.length > 100) {
          print('Trimming to exactly 100 frames');
          frameFiles.removeRange(100, frameFiles.length);
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

  Future<void> _resetGphoto2Camera() async {
    try {
      print('Resetting gphoto2 camera...');

      // Kill any existing gphoto2 processes
      await Process.run('wsl.exe', [
        'bash',
        '-c',
        'pkill -f gphoto2 2>/dev/null || true',
      ]);

      // Wait for processes to die
      await Future.delayed(const Duration(milliseconds: 500));

      // Reset camera connection
      await Process.run('wsl.exe', [
        'bash',
        '-c',
        'gphoto2 --reset 2>/dev/null || true',
      ]);

      print('Camera reset completed');
    } catch (e) {
      print('Camera reset error (non-fatal): $e');
    }
  }

  Future<bool> _checkCameraReady() async {
    try {
      // More comprehensive camera check
      final detectResult = await Process.run('wsl.exe', [
        'bash',
        '-c',
        'timeout 5s gphoto2 --auto-detect 2>&1',
      ]);

      if (detectResult.exitCode != 0) {
        print(
          'Camera detection failed with exit code: ${detectResult.exitCode}',
        );
        return false;
      }

      final output = detectResult.stdout.toString();
      print('Camera detection output: $output');

      // Check for Canon EOS specifically
      if (output.contains('Canon') && output.contains('EOS')) {
        print('Canon EOS camera detected and ready');
        return true;
      }

      if (output.contains('No cameras detected')) {
        print('No cameras detected by gphoto2');
        return false;
      }

      return output.trim().isNotEmpty && !output.contains('error');
    } catch (e) {
      print('Camera ready check error: $e');
      return false;
    }
  }
}

final videoProvider = AsyncNotifierProvider<VideoNotifier, VideoState>(
  () => VideoNotifier(),
);
