import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PhotoNotifier extends AsyncNotifier<PhotoState> {
  MediaStream? _videoStream;
  MediaRecorder? _mediaRecorder;
  RTCVideoRenderer? _videoRenderer;

  @override
  Future<PhotoState> build() async {
    final tempPath = await getTemporaryDirectory();
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

  Future<void> _initializeVideoCamera() async {
    try {
      final printerStateAsync = ref.read(printerProvider);
      final selectedVideoCameraDeviceId = printerStateAsync.hasValue
          ? printerStateAsync.value?.videoCameraName
          : null;

      print(
        'Initializing video camera in photo notifier for background recording',
      );

      // Get user media constraints for video recording
      final Map<String, dynamic> constraints = {
        'video': selectedVideoCameraDeviceId != null
            ? {
                'deviceId': selectedVideoCameraDeviceId,
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : {
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              },
        'audio': true, // Enable audio for video recording
      };

      _videoStream = await navigator.mediaDevices.getUserMedia(constraints);

      print(
        'Video camera initialized in photo notifier for background recording',
      );
    } catch (e) {
      print('Error initializing video camera in photo notifier: $e');
      throw e;
    }
  }

  Future<void> startVideoRecording() async {
    // Initialize video camera only when recording starts
    if (_videoStream == null) {
      await _initializeVideoCamera();
    }

    if (_videoStream == null) {
      throw Exception('Video camera not initialized for recording');
    }

    try {
      print('Starting video recording in photo notifier...');

      // Create MediaRecorder for recording
      _mediaRecorder = MediaRecorder();

      // Generate a temporary file path for recording
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available for video recording path.");
      }

      final videoFileName =
          'recording_${DateTime.now().millisecondsSinceEpoch}.webm';
      final videoPath = p.join(currentState.tempPath, videoFileName);

      await _mediaRecorder!.start(
        videoPath,
        videoTrack: _videoStream!.getVideoTracks().first,
      );

      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to start video recording.");
        }
        return currentState.copyWith(isRecording: true);
      });

      print('Video recording started successfully in photo notifier');
    } catch (e) {
      print('Failed to start video recording in photo notifier: $e');
      throw Exception('Video recording failed: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    if (_mediaRecorder == null) {
      print('No video recording to stop in photo notifier');
      return;
    }

    try {
      print('Stopping video recording in photo notifier...');
      final recordedPath = await _mediaRecorder!.stop();
      _mediaRecorder = null;

      // Convert webm to mp4 and save
      await _saveAndProcessRecording(recordedPath);

      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to stop video recording.");
        }
        return currentState.copyWith(isRecording: false);
      });

      print('Video recording stopped and processed in photo notifier');
    } catch (e) {
      print('Error stopping video recording in photo notifier: $e');

      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to update recording state.");
        }
        return currentState.copyWith(isRecording: false);
      });

      throw Exception('Failed to stop video recording: $e');
    }
  }

  Future<void> _saveAndProcessRecording(String recordedPath) async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to save recording.");
    }

    try {
      // Convert webm to mp4
      final mp4Path = await _convertWebmToMp4(recordedPath);

      // Update state with mp4 path
      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to update video path.");
        }
        return currentState.copyWith(videoPath: mp4Path);
      });

      // Process the video with VHS filter
      await _processVideoWithVHSFilter();
    } catch (e) {
      print('Error processing recording: $e');
      // Set the raw recording path if processing fails
      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to update video path.");
        }
        return currentState.copyWith(videoPath: recordedPath);
      });
    }
  }

  Future<String> _convertWebmToMp4(String webmPath) async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available for conversion.");
    }

    final mp4FileName =
        'converted_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final mp4Path = p.join(currentState.tempPath, mp4FileName);

    try {
      print('Converting webm to mp4: $webmPath -> $mp4Path');

      final ffmpegArgs = [
        '-i', webmPath,
        '-c:v', 'libx264',
        '-c:a', 'aac',
        '-movflags', '+faststart',
        '-y', // Overwrite output
        mp4Path,
      ];

      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        // Clean up original webm file
        final webmFile = File(webmPath);
        if (await webmFile.exists()) {
          await webmFile.delete();
        }

        print('Successfully converted to mp4: $mp4Path');
        return mp4Path;
      } else {
        print('FFmpeg conversion failed: ${process.stderr}');
        throw Exception('Conversion failed: ${process.stderr}');
      }
    } catch (e) {
      print('Error converting webm to mp4: $e');
      // Return original webm if conversion fails
      return webmPath;
    }
  }

  Future<void> _processVideoWithVHSFilter() async {
    final currentState = state.value;
    if (currentState == null || currentState.videoPath == null) {
      throw Exception("No raw video available for VHS processing");
    }

    final rawVideoFile = File(currentState.videoPath!);
    if (!await rawVideoFile.exists()) {
      throw Exception("Raw video file not found: ${currentState.videoPath}");
    }

    final processedVideoFileName =
        'vhs_processed_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final processedVideoPath = p.join(
      currentState.tempPath,
      processedVideoFileName,
    );

    try {
      print('Processing raw video with VHS filter...');
      print('Input: ${currentState.videoPath}');
      print('Output: $processedVideoPath');

      // Apply VHS filter
      final ffmpegArgs = [
        '-i', currentState.videoPath!,
        '-y', // Overwrite output
        '-v', 'info',
        '-vf',
        [
          'scale=640:480', // Standard definition for VHS effect
          'fps=24', // Standardize frame rate
          'noise=alls=15:allf=t', // Add noise for VHS effect
          'eq=contrast=1.4:brightness=0.1:saturation=1.5', // Enhance colors
          'unsharp=5:5:1.5:5:5:0.0', // Add slight blur
        ].join(','),
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        '-movflags', '+faststart',
        '-c:a', 'aac',
        '-b:a', '128k',
        processedVideoPath,
      ];

      print('FFmpeg VHS processing: ffmpeg ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final processedFile = File(processedVideoPath);
        if (await processedFile.exists()) {
          final fileSize = await processedFile.length();
          print('VHS processing completed successfully, size: $fileSize bytes');

          // Keep both raw and processed videos (raw for backup, processed for upload)
          // The soft copy service will use the processed version
          print('VHS filter applied successfully');
        } else {
          throw Exception('Processed video file was not created');
        }
      } else {
        print('VHS processing failed: ${process.stderr}');
        throw Exception('VHS processing failed: ${process.stderr}');
      }
    } catch (e) {
      print('Error in VHS processing: $e');
      // If VHS processing fails, we still have the raw video
      print('VHS processing failed, will use raw video as fallback');
    }
  }

  Future<void> _createFallbackVideo(String outputPath) async {
    try {
      print('Creating fallback video at: $outputPath');

      final outputDir = Directory(p.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final ffmpegArgs = [
        '-f',
        'lavfi',
        '-i',
        'testsrc=duration=10:size=640x480:rate=25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=1000:duration=10',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        '-shortest',
        '-y',
        outputPath,
      ];

      print('Running FFmpeg fallback: ${ffmpegArgs.join(' ')}');
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final fileSize = await outputFile.length();
          print('Fallback video created successfully, size: $fileSize bytes');
        }
      } else {
        print('Fallback video creation failed: ${process.stderr}');
      }
    } catch (e) {
      print('Error creating fallback video: $e');
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

        // Don't initialize video camera here - will be done when recording starts

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
      final newState = currentState.copyWith(captureCount: 4);
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

      // Stop video recording if active
      if (_mediaRecorder != null) {
        try {
          await _mediaRecorder!.stop();
        } catch (e) {
          print('Error stopping video recording during clear: $e');
        }
      }

      // Delete all photo files from the temporary directory
      for (final photo in currentState.photos) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete video files if they exist
      if (currentState.videoPath != null) {
        final videoFile = File(currentState.videoPath!);
        if (await videoFile.exists()) {
          await videoFile.delete();
        }
      }

      // Clean up processed video files
      final tempDir = Directory(currentState.tempPath);
      await for (final entity in tempDir.list()) {
        if (entity is File &&
            (entity.path.contains('vhs_processed_') ||
                entity.path.contains('raw_session_'))) {
          try {
            await entity.delete();
            print('Cleaned up video file: ${entity.path}');
          } catch (e) {
            print('Error cleaning up video file: $e');
          }
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

    print('Total media files: ${mediaFiles.length}');
    return mediaFiles;
  }

  // Get processed video specifically for soft copy upload
  Future<File?> getProcessedVideo() async {
    final currentState = state.value;
    if (currentState == null) {
      return null;
    }

    // Look for VHS processed video files in temp directory
    final tempDir = Directory(currentState.tempPath);
    final files = await tempDir.list().toList();

    for (final file in files) {
      if (file is File &&
          file.path.contains('vhs_processed_') &&
          file.path.endsWith('.mp4')) {
        if (await file.exists()) {
          print('Found VHS processed video: ${file.path}');
          return file;
        }
      }
    }

    print('No VHS processed video found');
    return null;
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
}

final photoProvider = AsyncNotifierProvider<PhotoNotifier, PhotoState>(
  () => PhotoNotifier(),
);
