import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PhotoNotifier extends AsyncNotifier<PhotoState> {
  // Remove video controller since recording is now handled by capture screen
  Process? _ffmpegProcess;
  static const String _tmuxSession = 'photocafe';

  @override
  Future<PhotoState> build() async {
    final tempPath = await getTemporaryDirectory();
    // Create a dedicated subdirectory to avoid conflicts and for easier cleanup.
    final photoTempDir = Directory(p.join(tempPath.path, 'photos'));
    if (!await photoTempDir.exists()) {
      await photoTempDir.create(recursive: true);
    }
    return PhotoState(
      photos: [],
      tempPath: photoTempDir.path,
      captureCount: 4,
      isRecording: false,
      videoPath: null,
    );
  }

  Future<void> saveVideoFromCapture(XFile videoXFile) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to save video.");
      }

      final videoFileName =
          'session_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoPath = p.join(currentState.tempPath, videoFileName);

      try {
        // Read bytes from XFile and write to our designated path
        final videoBytes = await videoXFile.readAsBytes();
        final targetFile = File(videoPath);
        await targetFile.writeAsBytes(videoBytes);

        print('Video saved from capture to: $videoPath');

        // Verify the file was written correctly
        final fileSize = await targetFile.length();
        print('Video file size: $fileSize bytes');

        if (fileSize < 1024) {
          print('Video file too small, creating fallback...');
          await _createFallbackVideo(videoPath);
        }

        return currentState.copyWith(videoPath: videoPath);
      } catch (e) {
        print('Error saving video from capture: $e');

        // Create fallback video if saving fails
        await _createFallbackVideo(videoPath);

        return currentState.copyWith(videoPath: videoPath);
      }
    });
  }

  Future<void> setVideoRecordingState(bool isRecording) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to set recording state.");
      }

      return currentState.copyWith(isRecording: isRecording);
    });
  }

  Future<void> _createFallbackVideo(String outputPath) async {
    try {
      print('Creating fallback video at: $outputPath');

      // Ensure the directory exists
      final outputDir = Directory(p.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final ffmpegArgs = [
        '-f', 'lavfi',
        '-i', 'testsrc=duration=10:size=640x480:rate=25',
        '-f', 'lavfi',
        '-i', 'sine=frequency=1000:duration=10',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-shortest',
        '-y', // Overwrite output file
        outputPath,
      ];

      print('Running FFmpeg with args: ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          print('Fallback video created successfully, size: $fileSize bytes');
        } else {
          print('Fallback video creation completed but file not found');
        }
      } else {
        print('Fallback video creation failed: ${process.stderr}');
        print('FFmpeg stdout: ${process.stdout}');
      }
    } catch (e) {
      print('Error creating fallback video: $e');
    }
  }

  Future<File?> captureWithGphoto2() async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to capture photo.");
    }

    final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fullWindowsPath = p.join(currentState.tempPath, fileName);

    // Convert Windows path to WSL path format
    final wslPath = fullWindowsPath
        .replaceAll(r'\', '/')
        .replaceAll('C:', '/mnt/c');

    try {
      // Ensure tmux session exists and is ready
      await _ensureTmuxSession();

      // Use tmux session for instant gphoto2 capture
      for (int attempt = 1; attempt <= 2; attempt++) {
        // reset gphoto2

        await _resetGphoto2CameraInTmux();

        await Future.delayed(const Duration(milliseconds: 500));

        final result = await Process.run('wsl.exe', [
          'tmux',
          'send-keys',
          '-t',
          _tmuxSession,
          'gphoto2 --capture-image-and-download --stdout > "$wslPath" 2>/dev/null && echo "CAPTURE_SUCCESS" || echo "CAPTURE_FAILED"',
          'Enter',
        ]);

        if (result.exitCode == 0) {
          // Wait for capture to complete and check result
          await Future.delayed(const Duration(milliseconds: 500));
          final file = File(fullWindowsPath);

          // Wait a bit more for file to be fully written
          for (int i = 0; i < 10; i++) {
            if (await file.exists()) {
              final fileSize = await file.length();
              if (fileSize > 1024) {
                print(
                  'gphoto2 photo captured successfully via tmux, size: $fileSize bytes',
                );
                return file;
              }
            }
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }

        // If failed and not last attempt, reset camera in tmux session
        if (attempt < 2) {
          print(
            'gphoto2 photo capture failed, resetting camera in tmux session...',
          );
          await _resetGphoto2CameraInTmux();
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      print('All gphoto2 photo capture attempts failed');
    } catch (e) {
      print('gphoto2 photo capture error: $e');
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
        print('Tmux session $_tmuxSession is ready');
      }
    } catch (e) {
      print('Error checking tmux session: $e');
      await _createTmuxSession();
    }
  }

  Future<void> _createTmuxSession() async {
    try {
      print('Creating tmux session $_tmuxSession...');

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
        'echo "PhotoCafe gphoto2 session ready for photos"',
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

      print('Tmux session created and initialized');
    } catch (e) {
      print('Error creating tmux session: $e');
    }
  }

  Future<void> _resetGphoto2CameraInTmux() async {
    try {
      print('Resetting gphoto2 camera in tmux session...');

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

      print('Camera reset completed in tmux session');
    } catch (e) {
      print('Camera reset error in tmux (non-fatal): $e');
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
        print('Camera detection output from tmux: $output');

        // Check for Canon EOS specifically
        if (output.contains('Canon') && output.contains('EOS')) {
          print('Canon EOS camera detected and responsive via tmux');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Camera ready check error via tmux: $e');
      return false;
    }
  }

  Future<void> addPhoto(Uint8List imageBytes) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to add a photo.");
      }

      // Always process for landscape orientation (4:3 aspect ratio) for all photos
      final processedImageBytes = await _processImageForLandscape(imageBytes);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = p.join(currentState.tempPath, fileName);
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(processedImageBytes);

      final newPhoto = PhotoModel(
        imagePath: imagePath,
        index: currentState.photos.isNotEmpty
            ? (currentState.photos
                      .map((p) => p.index)
                      .reduce((a, b) => a > b ? a : b) +
                  1)
            : 0,
      );

      final updatedPhotos = List<PhotoModel>.from(currentState.photos)
        ..add(newPhoto);

      return currentState.copyWith(photos: updatedPhotos);
    });
  }

  Future<Uint8List> _processImageForPortrait(Uint8List imageBytes) async {
    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return imageBytes;

      // Calculate target dimensions for 5:6 aspect ratio
      final targetWidth = 1000;
      final targetHeight = 1200;

      // Resize and crop to 5:6 aspect ratio
      img.Image processedImage;

      if (originalImage.width / originalImage.height > 5 / 6) {
        // Image is wider than 5:6, crop horizontally
        final newWidth = (originalImage.height * 5 / 6).round();
        final cropX = (originalImage.width - newWidth) ~/ 2;
        processedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: 0,
          width: newWidth,
          height: originalImage.height,
        );
      } else {
        // Image is taller than 5:6, crop vertically
        final newHeight = (originalImage.width * 6 / 5).round();
        final cropY = (originalImage.height - newHeight) ~/ 2;
        processedImage = img.copyCrop(
          originalImage,
          x: 0,
          y: cropY,
          width: originalImage.width,
          height: newHeight,
        );
      }

      // Resize to target dimensions
      processedImage = img.copyResize(
        processedImage,
        width: targetWidth,
        height: targetHeight,
      );

      return img.encodeJpg(processedImage);
    } catch (e) {
      print('Error processing image for portrait: $e');
      return imageBytes; // Return original if processing fails
    }
  }

  Future<Uint8List> _processImageForLandscape(Uint8List imageBytes) async {
    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return imageBytes;

      // Calculate target dimensions for 4:3 aspect ratio
      final targetWidth = 1200;
      final targetHeight = 900;

      // Resize and crop to 4:3 aspect ratio
      img.Image processedImage;

      if (originalImage.width / originalImage.height > 4 / 3) {
        // Image is wider than 4:3, crop horizontally
        final newWidth = (originalImage.height * 4 / 3).round();
        final cropX = (originalImage.width - newWidth) ~/ 2;
        processedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: 0,
          width: newWidth,
          height: originalImage.height,
        );
      } else {
        // Image is taller than 4:3, crop vertically
        final newHeight = (originalImage.width * 3 / 4).round();
        final cropY = (originalImage.height - newHeight) ~/ 2;
        processedImage = img.copyCrop(
          originalImage,
          x: 0,
          y: cropY,
          width: originalImage.width,
          height: newHeight,
        );
      }

      // Resize to target dimensions
      processedImage = img.copyResize(
        processedImage,
        width: targetWidth,
        height: targetHeight,
      );

      return img.encodeJpg(processedImage);
    } catch (e) {
      print('Error processing image for landscape: $e');
      return imageBytes; // Return original if processing fails
    }
  }

  Future<void> setCaptureCount(int count) async {
    print('setCaptureCount called with count: $count (but will always use 4)');

    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        print(
          'Warning: Photo state was null when setting capture count, creating new state',
        );
        final tempPath = await getTemporaryDirectory();
        final photoTempDir = Directory(p.join(tempPath.path, 'photos'));
        if (!await photoTempDir.exists()) {
          await photoTempDir.create(recursive: true);
        }
        final newState = PhotoState(
          photos: [],
          tempPath: photoTempDir.path,
          captureCount: 4, // Always capture 4 photos regardless of layout
          isRecording: false,
          videoPath: null,
        );
        print('Created new state with capture count: ${newState.captureCount}');
        return newState;
      }

      print(
        'Setting capture count from ${currentState.captureCount} to 4 (always capture 4 regardless of layout)',
      );
      final newState = currentState.copyWith(
        captureCount:
            4, // Always capture 4 photos - layout only affects arrangement
      );
      print('New state capture count: ${newState.captureCount}');

      await Future.delayed(const Duration(milliseconds: 50));

      return newState;
    });

    final finalState = state.value;
    print(
      'setCaptureCount completed. Final state capture count: ${finalState?.captureCount}',
    );
  }

  Future<void> clearPhoto(int index) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) return state.value!;

      final photoToRemove = currentState.photos.firstWhere(
        (photo) => photo.index == index,
      );

      final file = File(photoToRemove.imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      return currentState.copyWith(
        photos: currentState.photos
            .where((photo) => photo.index != index)
            .toList(),
      );
    });
  }

  Future<void> clearAllPhotos() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) return state.value!;

      // Stop FFmpeg process if running (video recording is now handled by capture screen)
      if (_ffmpegProcess != null) {
        _ffmpegProcess!.kill();
        _ffmpegProcess = null;
      }

      // Delete all photo files from the temporary directory
      for (final photo in currentState.photos) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete video file if exists
      if (currentState.videoPath != null) {
        final videoFile = File(currentState.videoPath!);
        if (await videoFile.exists()) {
          await videoFile.delete();
        }
      }

      return currentState.copyWith(
        photos: [],
        videoPath: null,
        isRecording: false,
      );
    });
  }

  Future<void> switchPhotoOrder(int indexA, int indexB) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to switch photo order.");
      }

      final photos = List<PhotoModel>.from(currentState.photos);

      // Find photos by their current indices
      final photoAIndex = photos.indexWhere((p) => p.index == indexA);
      final photoBIndex = photos.indexWhere((p) => p.index == indexB);

      if (photoAIndex == -1 || photoBIndex == -1) {
        throw Exception("Photo not found for switching");
      }

      final photoA = photos[photoAIndex];
      final photoB = photos[photoBIndex];

      // Create new photos with swapped indices
      final newPhotoA = photoA.copyWith(index: indexB);
      final newPhotoB = photoB.copyWith(index: indexA);

      // Update the list
      photos[photoAIndex] = newPhotoA;
      photos[photoBIndex] = newPhotoB;

      return currentState.copyWith(photos: photos);
    });
  }

  Future<void> reorderPhotos(List<PhotoModel> newOrder) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to reorder photos.");
      }

      // Assign new indices based on the new order
      final reorderedPhotos = newOrder.asMap().entries.map((entry) {
        return entry.value.copyWith(index: entry.key);
      }).toList();

      return currentState.copyWith(photos: reorderedPhotos);
    });
  }

  Future<void> applyFilters(
    img.Image Function(img.Image) filterFunction,
  ) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to apply filters.");
      }

      final updatedPhotos = <PhotoModel>[];

      for (final photo in currentState.photos) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          // Read and decode the image
          final imageBytes = await file.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);

          if (originalImage != null) {
            // Apply the filter
            final filteredImage = filterFunction(originalImage);

            // Encode back to JPEG
            final filteredBytes = img.encodeJpg(filteredImage);

            // Create new file path for filtered image
            final fileName =
                'filtered_${DateTime.now().millisecondsSinceEpoch}_${photo.index}.jpg';
            final filteredPath = p.join(currentState.tempPath, fileName);
            final filteredFile = File(filteredPath);

            // Write filtered image
            await filteredFile.writeAsBytes(filteredBytes);

            // Delete old file
            await file.delete();

            // Update photo model with new path
            updatedPhotos.add(photo.copyWith(imagePath: filteredPath));
          } else {
            // If image couldn't be decoded, keep original
            updatedPhotos.add(photo);
          }
        } else {
          // If file doesn't exist, keep original
          updatedPhotos.add(photo);
        }
      }

      return currentState.copyWith(photos: updatedPhotos);
    });
  }

  Future<String?> processVideoWithVHSFilter({
    required Function(double) onProgress,
  }) async {
    final currentState = state.value;
    if (currentState == null || currentState.videoPath == null) {
      throw Exception("No video available for processing");
    }

    final videoFile = File(currentState.videoPath!);
    if (!await videoFile.exists()) {
      throw Exception("Video file not found at: ${currentState.videoPath}");
    }

    // Check if the video file is valid
    final fileSize = await videoFile.length();
    print('Processing video file size: $fileSize bytes');

    if (fileSize < 1024) {
      throw Exception(
        "Video file is too small or corrupted (${fileSize} bytes)",
      );
    }

    // Create output path for processed video in the same temp directory
    final outputFileName =
        'vhs_filtered_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final outputPath = p.join(currentState.tempPath, outputFileName);

    try {
      onProgress(0.1); // Starting

      // Validate input video with ffprobe first
      try {
        print('Validating input video with ffprobe...');
        final probeResult = await Process.run('ffprobe', [
          '-v',
          'quiet',
          '-print_format',
          'json',
          '-show_format',
          '-show_streams',
          currentState.videoPath!,
        ]);

        if (probeResult.exitCode != 0) {
          print('FFprobe failed: ${probeResult.stderr}');
          throw Exception(
            'Input video validation failed: ${probeResult.stderr}',
          );
        }

        print('Video validation successful');
        print('FFprobe output: ${probeResult.stdout}');
      } catch (e) {
        print('Video validation error: $e');
        // Continue anyway, FFmpeg might still be able to process it
      }

      onProgress(0.2); // Validation complete

      print('Starting VHS filter processing...');
      print('Input: ${currentState.videoPath}');
      print('Output: $outputPath');

      // Apply VHS filter with more robust settings
      final ffmpegArgs = [
        '-i', currentState.videoPath!,
        '-t', '40', // Limit to 40 seconds max
        '-y', // Overwrite output
        '-v', 'info', // More verbose logging
        '-vf',
        [
          'scale=640:480', // Resize to standard definition
          'fps=24', // Standardize frame rate
          'noise=alls=10:allf=t', // Add noise for VHS effect
          'eq=contrast=1.3:brightness=0.05:saturation=1.4', // Adjust colors
          'unsharp=5:5:1.0:5:5:0.0', // Add slight blur
        ].join(','),
        '-c:v', 'libx264',
        '-preset', 'fast', // Faster than medium
        '-crf', '23', // Better quality than 28
        '-movflags', '+faststart',
        '-c:a', 'aac', // Keep audio but re-encode
        '-b:a', '128k', // Audio bitrate
        outputPath,
      ];

      onProgress(0.3); // Starting processing

      print('FFmpeg command: ffmpeg ${ffmpegArgs.join(' ')}');

      final process = await Process.start('ffmpeg', ffmpegArgs);

      // Capture stderr for progress monitoring
      final stderrBuffer = StringBuffer();
      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        stderrBuffer.write(data);
        print('FFmpeg stderr: $data');

        // Parse progress from time information
        final timeRegex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})');
        final match = timeRegex.firstMatch(data);
        if (match != null) {
          final hours = int.parse(match.group(1)!);
          final minutes = int.parse(match.group(2)!);
          final seconds = int.parse(match.group(3)!);
          final totalSeconds = hours * 3600 + minutes * 60 + seconds;

          // Estimate progress (assuming 10 second video)
          final estimatedDuration = 10;
          final progress = 0.3 + (totalSeconds / estimatedDuration) * 0.6;
          onProgress(progress.clamp(0.3, 0.9));
        }
      });

      // Capture stdout
      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        print('FFmpeg stdout: $data');
      });

      final exitCode = await process.exitCode;
      print('FFmpeg finished with exit code: $exitCode');

      if (exitCode != 0) {
        print('FFmpeg stderr output: ${stderrBuffer.toString()}');
        throw Exception(
          'VHS filter processing failed with exit code: $exitCode',
        );
      }

      onProgress(0.95);

      // Verify output file
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Processed video file was not created at: $outputPath');
      }

      final outputSize = await outputFile.length();
      if (outputSize < 1024) {
        throw Exception('Processed video file is too small: $outputSize bytes');
      }

      print('VHS processing completed successfully!');
      print('Output file: $outputPath');
      print('Output size: $outputSize bytes');

      onProgress(1.0);
      return outputPath;
    } catch (e) {
      print('VHS processing error: $e');

      // Fallback: copy the original file with a different name
      try {
        print('Creating fallback processed video...');
        final inputBytes = await File(currentState.videoPath!).readAsBytes();
        await File(outputPath).writeAsBytes(inputBytes);

        onProgress(1.0);
        print('Used original video as VHS processed fallback');
        return outputPath;
      } catch (fallbackError) {
        print('Fallback creation failed: $fallbackError');
        throw Exception('VHS processing and fallback failed: $e');
      }
    }
  }

  Future<List<File>> getAllMediaFiles() async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to get media files");
    }

    final mediaFiles = <File>[];

    // Add all photo files
    for (final photo in currentState.photos) {
      final file = File(photo.imagePath);
      if (await file.exists()) {
        mediaFiles.add(file);
        print('Added photo file: ${photo.imagePath}');
      } else {
        print('Photo file not found: ${photo.imagePath}');
      }
    }

    // Add video file if available (use original, not processed for now)
    if (currentState.videoPath != null) {
      final videoFile = File(currentState.videoPath!);
      if (await videoFile.exists()) {
        mediaFiles.add(videoFile);
        print('Added video file: ${currentState.videoPath}');
      } else {
        print('Video file not found: ${currentState.videoPath}');
      }
    }

    print('Total media files: ${mediaFiles.length}');
    return mediaFiles;
  }

  // Add method to get processed video specifically
  Future<File?> getProcessedVideo() async {
    final currentState = state.value;
    if (currentState == null || currentState.videoPath == null) {
      return null;
    }

    // Look for processed video files in temp directory
    final tempDir = Directory(currentState.tempPath);
    final files = await tempDir.list().toList();

    for (final file in files) {
      if (file is File &&
          file.path.contains('vhs_filtered') &&
          file.path.endsWith('.mp4')) {
        if (await file.exists()) {
          print('Found processed video: ${file.path}');
          return file;
        }
      }
    }

    print('No processed video found, returning original');
    return File(currentState.videoPath!);
  }
}

final photoProvider = AsyncNotifierProvider<PhotoNotifier, PhotoState>(
  () => PhotoNotifier(),
);
