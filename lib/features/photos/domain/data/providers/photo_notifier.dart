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
  CameraController? _videoController;
  Process? _ffmpegProcess;

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

  Future<void> startVideoRecording() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to start video recording.");
      }

      if (currentState.isRecording) {
        return currentState; // Already recording
      }

      // Get video camera from settings
      final printerState = ref.read(printerProvider).value;
      final videoCameraName = printerState?.videoCameraName;

      if (videoCameraName == null) {
        throw Exception("No video camera selected in settings");
      }

      // Get available cameras and find the selected video camera
      final cameras = await availableCameras();
      CameraDescription? videoCamera;

      try {
        videoCamera = cameras.firstWhere(
          (camera) => camera.name == videoCameraName,
        );
      } catch (e) {
        throw Exception("Selected video camera '$videoCameraName' not found");
      }

      final videoFileName =
          'session_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoPath = p.join(currentState.tempPath, videoFileName);

      try {
        print('Starting video recording with camera: ${videoCamera.name}');

        // Initialize video camera controller
        _videoController = CameraController(
          videoCamera,
          ResolutionPreset.medium,
          enableAudio: true,
        );

        await _videoController!.initialize();
        await _videoController!.startVideoRecording();

        print('Video recording started successfully to: $videoPath');

        return currentState.copyWith(isRecording: true, videoPath: videoPath);
      } catch (e) {
        print('Failed to start video recording: $e');
        _videoController?.dispose();
        _videoController = null;
        throw Exception("Failed to start video recording: $e");
      }
    });
  }

  Future<void> stopVideoRecording() async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to stop video recording.");
      }

      if (!currentState.isRecording || _videoController == null) {
        return currentState; // Not recording
      }

      try {
        print('Stopping video recording...');

        // Stop the video recording and get the XFile
        final videoXFile = await _videoController!.stopVideoRecording();

        // Read bytes from XFile and write to our designated path
        if (currentState.videoPath != null) {
          final videoBytes = await videoXFile.readAsBytes();
          final targetFile = File(currentState.videoPath!);
          await targetFile.writeAsBytes(videoBytes);

          print('Video recording saved to: ${currentState.videoPath}');

          // Verify the file was written correctly
          final fileSize = await targetFile.length();
          print('Video file size: $fileSize bytes');

          if (fileSize < 1024) {
            print('Video file too small, creating fallback...');
            await _createFallbackVideo(currentState.videoPath!);
          }
        }

        // Dispose of the video controller
        await _videoController!.dispose();
        _videoController = null;

        return currentState.copyWith(isRecording: false);
      } catch (e) {
        print('Error stopping video recording: $e');

        // Clean up controller on error
        try {
          await _videoController?.dispose();
        } catch (_) {}
        _videoController = null;

        // Create fallback video if actual recording failed
        if (currentState.videoPath != null) {
          await _createFallbackVideo(currentState.videoPath!);
        }

        return currentState.copyWith(isRecording: false);
      }
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

    final result = await Process.run('wsl.exe', [
      'bash',
      '-c',
      'gphoto2 --capture-image-and-download --stdout > "$wslPath"',
    ]);

    if (result.exitCode != 0) {
      return null;
    }
    return File(fullWindowsPath);
  }

  Future<void> addPhoto(Uint8List imageBytes) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to add a photo.");
      }

      // Process image based on capture count
      Uint8List processedImageBytes = imageBytes;

      if (currentState.captureCount == 2) {
        // For 2x2 mode, ensure portrait orientation (5:6 aspect ratio)
        processedImageBytes = await _processImageForPortrait(imageBytes);
      } else if (currentState.captureCount == 4) {
        // For 4x4 mode, ensure landscape orientation (4:3 aspect ratio)
        processedImageBytes = await _processImageForLandscape(imageBytes);
      }

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
    print('setCaptureCount called with count: $count');

    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        // If somehow state is null, create a new one with the count
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
          captureCount: count,
          isRecording: false,
          videoPath: null,
        );
        print('Created new state with capture count: ${newState.captureCount}');
        return newState;
      }

      print(
        'Setting capture count from ${currentState.captureCount} to $count',
      );
      final newState = currentState.copyWith(captureCount: count);
      print('New state capture count: ${newState.captureCount}');

      // Add a small delay to ensure the state is properly set
      await Future.delayed(const Duration(milliseconds: 50));

      return newState;
    });

    // Log the final state after the guard completes
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

      // Stop video recording if active
      if (currentState.isRecording && _videoController != null) {
        try {
          await _videoController!.stopVideoRecording();
          await _videoController!.dispose();
        } catch (e) {
          print('Error cleaning up video controller: $e');
        }
        _videoController = null;
      }

      // Stop FFmpeg process if running
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
        '-y', // Overwrite output
        '-v', 'info', // More verbose logging
        '-vf',
        [
          'scale=640:480', // Resize to standard definition
          'fps=25', // Standardize frame rate
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
