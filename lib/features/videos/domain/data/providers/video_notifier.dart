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
  static const String _tmuxSession = 'photocafe';

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

    print('Attempting gphoto2 video capture via tmux to: $wslPath');

    try {
      // Ensure tmux session exists and is ready
      await _ensureTmuxSession();

      // Try capture with fewer retries since tmux session is persistent
      for (int attempt = 1; attempt <= 2; attempt++) {
        // Send capture command to tmux session
        await Process.run('wsl.exe', [
          'tmux',
          'send-keys',
          '-t',
          _tmuxSession,
          'gphoto2 --capture-movie=7s --stdout > "$wslPath" 2>/dev/null && echo "VIDEO_CAPTURE_SUCCESS" || echo "VIDEO_CAPTURE_FAILED"',
          'Enter',
        ]);

        // Wait for capture to complete (7s + 3s buffer)
        await Future.delayed(const Duration(seconds: 10));

        final mjpegFile = File(fullWindowsPath);

        // Wait for file to be fully written
        for (int i = 0; i < 15; i++) {
          if (await mjpegFile.exists()) {
            final fileSize = await mjpegFile.length();
            await _resetGphoto2CameraInTmux();
            if (fileSize > 1024) {
              print('gphoto2 MJPEG captured via tmux, size: $fileSize bytes');
              // Convert MJPEG to MP4 before returning
              final mp4File = await _convertMjpegToMp4(mjpegFile);
              return mp4File;
            }
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // If failed and not last attempt, reset camera in tmux session
        if (attempt < 2) {
          print(
            'gphoto2 video capture failed, resetting camera in tmux session...',
          );
          await _resetGphoto2CameraInTmux();
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }

      print('All gphoto2 video capture attempts failed, will use fallback');
    } catch (e) {
      print('gphoto2 video capture error: $e');
    }

    return null;
  }

  Future<void> _ensureTmuxSession() async {
    try {
      // Check if session exists
      final checkResult = await Process.run('wsl.exe', [
        'tmux',
        'has-session',
        '-t',
        _tmuxSession,
      ]);

      if (checkResult.exitCode != 0) {
        print('Tmux session not found, creating new one...');
        await _createTmuxSession();
      } else {
        print('Tmux session $_tmuxSession is ready for video');
      }
    } catch (e) {
      print('Error checking tmux session: $e');
      await _createTmuxSession();
    }
  }

  Future<void> _createTmuxSession() async {
    try {
      print('Creating tmux session $_tmuxSession for video...');

      // Kill existing session if any
      await Process.run('wsl.exe', [
        'tmux',
        'kill-session',
        '-t',
        _tmuxSession,
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      // Create new session
      await Process.run('wsl.exe', [
        'tmux',
        'new-session',
        '-d',
        '-s',
        _tmuxSession,
      ]);

      // Initialize gphoto2 in the session
      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'echo "PhotoCafe gphoto2 session ready for video"',
        'Enter',
      ]);

      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'gphoto2 --reset',
        'Enter',
      ]);

      print('Tmux session created and initialized for video');
    } catch (e) {
      print('Error creating tmux session for video: $e');
    }
  }

  Future<void> _resetGphoto2CameraInTmux() async {
    try {
      print('Resetting gphoto2 camera in tmux session for video...');

      // Kill any gphoto2 processes in the session
      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'C-c', // Send Ctrl+C to interrupt any running command
      ]);

      await Future.delayed(const Duration(milliseconds: 300));

      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'pkill -f gphoto2 2>/dev/null || true',
        'Enter',
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      // Reset camera
      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'gphoto2 --reset 2>/dev/null || true',
        'Enter',
      ]);

      print('Camera reset completed in tmux session for video');
    } catch (e) {
      print('Camera reset error in tmux for video (non-fatal): $e');
    }
  }

  Future<void> _resetGphoto2Camera() async {
    // Use tmux session instead of direct WSL calls
    await _resetGphoto2CameraInTmux();
  }

  Future<bool> _checkCameraReady() async {
    try {
      // Ensure tmux session exists
      await _ensureTmuxSession();

      // Check camera using tmux session
      await Process.run('wsl.exe', [
        'tmux',
        'send-keys',
        '-t',
        _tmuxSession,
        'timeout 3s gphoto2 --auto-detect 2>&1',
        'Enter',
      ]);

      // Wait for command to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      // Capture the output
      final result = await Process.run('wsl.exe', [
        'tmux',
        'capture-pane',
        '-t',
        _tmuxSession,
        '-p',
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        print('Camera detection output from tmux for video: $output');

        // Check for Canon EOS specifically
        if (output.contains('Canon') && output.contains('EOS')) {
          print('Canon EOS camera detected and responsive via tmux for video');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Camera ready check error via tmux for video: $e');
      return false;
    }
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
