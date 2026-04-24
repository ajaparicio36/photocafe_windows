import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/services/canon_camera_service.dart';
import 'package:photocafe_windows/services/webcam_video_service.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PhotoNotifier extends AsyncNotifier<PhotoState> {
  Process? _ffmpegProcess;

  // Background processing futures to avoid blocking UI
  Future<void>? _pendingVhsProcessing;
  String? _pendingRawVideoPath;

  // Path to the saved frame/photostrip PNG in the photos temp directory
  String? _savedFramePath;

  @override
  Future<PhotoState> build() async {
    final tempPath = await getTemporaryDirectory();
    final photoTempDir = Directory(p.join(tempPath.path, 'photos'));
    if (!await photoTempDir.exists()) {
      await photoTempDir.create(recursive: true);
    }

    // Don't initialize video camera here to avoid conflicts with photo camera
    // Video camera will be initialized when needed for recording

    return PhotoState(
      photos: [],
      tempPath: photoTempDir.path,
      captureCount: 4,
      isRecording: false,
      videoPath: null,
    );
  }

  Future<void> startVideoRecording() async {
    try {
      final webcamService = ref.read(webcamVideoServiceProvider);

      // Get the selected video camera name from settings
      final printerState = ref.read(printerProvider);
      final videoCameraName = printerState.value?.videoCameraName;

      print(
        'Starting webcam video recording in photo notifier '
        '(camera: ${videoCameraName ?? "default"})...',
      );

      // Initialize the webcam with the selected camera
      await webcamService.initialize(videoCameraName);

      // Start recording from the webcam
      await webcamService.startRecording();

      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to start video recording.");
        }
        return currentState.copyWith(isRecording: true);
      });

      print('Webcam video recording started successfully in photo notifier');
    } catch (e) {
      print('Failed to start webcam video recording in photo notifier: $e');
      throw Exception('Video recording failed: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    try {
      final webcamService = ref.read(webcamVideoServiceProvider);
      print('Stopping webcam video recording in photo notifier...');

      final videoPath = await webcamService.stopRecording();

      // Dispose the webcam controller to free resources
      // (Canon EDSDK live view continues unaffected)
      await webcamService.dispose();

      if (videoPath != null) {
        // Reference the webcam video for VHS processing
        await _referenceRecordedVideo(videoPath);

        // Start VHS processing in background - don't await here
        // This allows the UI to proceed to the filter screen immediately
        _startBackgroundVhsProcessing();
      } else {
        print('Warning: webcam stopRecording returned null path');
      }

      state = await AsyncValue.guard(() async {
        final currentState = state.value;
        if (currentState == null) {
          throw Exception("State is not available to stop video recording.");
        }
        return currentState.copyWith(isRecording: false);
      });

      print(
        'Webcam recording stopped in photo notifier (VHS processing continues in background)',
      );
    } catch (e) {
      print('Error stopping webcam video recording in photo notifier: $e');

      // Make sure webcam is disposed even on error
      try {
        final webcamService = ref.read(webcamVideoServiceProvider);
        await webcamService.dispose();
      } catch (_) {}

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

  /// Reference the recorded video path directly for VHS processing.
  /// No raw_session copy is made — the VHS processor reads straight
  /// from the source file and produces the processed mp4.
  Future<void> _referenceRecordedVideo(String videoFilePath) async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to save raw video.");
    }

    try {
      final sourceFile = File(videoFilePath);
      final fileSize = await sourceFile.length();
      print('Recorded video at: $videoFilePath ($fileSize bytes)');

      if (fileSize < 1024) {
        print('Recorded video file too small, creating fallback...');
        final fallbackPath = p.join(
          currentState.tempPath,
          'fallback_${DateTime.now().millisecondsSinceEpoch}.avi',
        );
        await _createFallbackVideo(fallbackPath);
        _pendingRawVideoPath = fallbackPath;

        state = await AsyncValue.guard(() async {
          final cs = state.value;
          if (cs == null) {
            throw Exception("State is not available to update video path.");
          }
          return cs.copyWith(videoPath: fallbackPath);
        });
        return;
      }

      // Reference the recorded video directly — no copy
      _pendingRawVideoPath = videoFilePath;

      state = await AsyncValue.guard(() async {
        final cs = state.value;
        if (cs == null) {
          throw Exception("State is not available to update video path.");
        }
        return cs.copyWith(videoPath: videoFilePath);
      });
    } catch (e) {
      print('Error referencing recorded video: $e');
      final fallbackPath = p.join(
        currentState.tempPath,
        'fallback_${DateTime.now().millisecondsSinceEpoch}.avi',
      );
      await _createFallbackVideo(fallbackPath);
      _pendingRawVideoPath = fallbackPath;

      state = await AsyncValue.guard(() async {
        final cs = state.value;
        if (cs == null) {
          throw Exception("State is not available to update video path.");
        }
        return cs.copyWith(videoPath: fallbackPath);
      });
    }
  }

  /// Start VHS processing in background without blocking
  void _startBackgroundVhsProcessing() {
    _pendingVhsProcessing = _processVideoWithVHSFilterAsync();
    _pendingVhsProcessing!
        .then((_) {
          print('Background VHS processing completed');
          _pendingVhsProcessing = null;
        })
        .catchError((e) {
          print('Background VHS processing failed: $e');
          _pendingVhsProcessing = null;
        });
  }

  /// Check if VHS processing is still in progress
  bool get isVhsProcessingInProgress => _pendingVhsProcessing != null;

  /// Wait for any pending VHS processing to complete (call before upload)
  Future<void> ensureVhsProcessingComplete() async {
    if (_pendingVhsProcessing != null) {
      print('Waiting for background VHS processing to complete...');
      await _pendingVhsProcessing;
      print('Background VHS processing finished');
    }
  }

  Future<void> _processVideoWithVHSFilter() async {
    await _processVideoWithVHSFilterAsync();
  }

  /// Async VHS processing that can run in background
  Future<void> _processVideoWithVHSFilterAsync() async {
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
      print('Processing raw video with VHS filter (background)...');
      print('Input: ${currentState.videoPath}');
      print('Output: $processedVideoPath');

      // Apply VHS filter with optimized settings for faster processing
      final ffmpegArgs = [
        '-i', currentState.videoPath!,
        '-y', // Overwrite output
        '-v', 'warning', // Reduce log verbosity for speed
        '-threads', '0', // Use all available CPU threads
        '-vf',
        [
          'scale=640:480', // Standard definition for VHS effect
          'fps=24', // Standardize frame rate
          'noise=alls=15:allf=t', // Add noise for VHS effect
          'eq=contrast=1.4:brightness=0.1:saturation=1.5', // Enhance colors
          'unsharp=5:5:1.5:5:5:0.0', // Add slight blur
        ].join(','),
        '-c:v', 'libx264',
        '-preset', 'veryfast', // Faster encoding preset (was 'fast')
        '-tune', 'fastdecode', // Optimize for fast decoding
        '-crf', '25', // Slightly lower quality for faster encoding (was 23)
        '-movflags', '+faststart',
        '-c:a', 'aac',
        '-b:a', '96k', // Lower audio bitrate for faster encoding (was 128k)
        processedVideoPath,
      ];

      print(
        'FFmpeg VHS processing (optimized): ffmpeg ${ffmpegArgs.join(' ')}',
      );
      final process = await Process.run('ffmpeg', ffmpegArgs);

      if (process.exitCode == 0) {
        final processedFile = File(processedVideoPath);
        if (await processedFile.exists()) {
          final fileSize = await processedFile.length();
          print('VHS processing completed successfully, size: $fileSize bytes');
          print('VHS filter applied successfully');

          // Delete the source AVI to save disk space — only keep the processed mp4
          try {
            final sourceAvi = File(currentState.videoPath!);
            if (await sourceAvi.exists()) {
              await sourceAvi.delete();
              print(
                'Deleted source AVI to save space: ${currentState.videoPath}',
              );
            }
          } catch (cleanupErr) {
            print('Warning: Could not delete source AVI: $cleanupErr');
          }
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

  // Legacy method kept for compatibility
  @Deprecated('Use _processVideoWithVHSFilterAsync instead')
  Future<void> _processVideoWithVHSFilterLegacy() async {
    await _processVideoWithVHSFilterAsync();
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

  /// Add a photo from raw image bytes (used for Canon EDSDK captured photos
  /// or contingency capture screenshots).
  Future<void> addPhoto(
    Uint8List imageBytes, {
    int layoutMode = 4,
    bool isLandscape = false,
  }) async {
    // Start image processing in parallel with state preparation
    final processingFuture = _processImageMinimal(
      imageBytes,
      layoutMode,
      isLandscape: isLandscape,
    );

    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to add a photo.");
      }

      // Wait for processing to complete
      final processedImageBytes = await processingFuture;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = p.join(currentState.tempPath, fileName);
      final imageFile = File(imagePath);

      // Use flush: false for faster writes (OS handles flushing)
      await imageFile.writeAsBytes(processedImageBytes, flush: false);

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

  /// Add a photo from a file path returned by Canon EDSDK's `takePicture()`
  /// or contingency capture. Copies the full-resolution camera file directly
  /// to the session temp directory, preserving original quality for both
  /// printing and soft-copy downloads.
  Future<void> addPhotoFromFile(
    String filePath, {
    int layoutMode = 4,
    bool isLandscape = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Photo file not found: $filePath');
    }

    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        throw Exception("State is not available to add a photo.");
      }

      // Copy the full-resolution Canon file directly to our temp directory.
      // This preserves the original camera quality (multi-megapixel JPEG)
      // for both frame building (printing) and soft-copy uploads.
      final sourceExtension = p.extension(filePath).toLowerCase();
      final ext = sourceExtension.isNotEmpty ? sourceExtension : '.jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final imagePath = p.join(currentState.tempPath, fileName);

      await file.copy(imagePath);

      final copiedFile = File(imagePath);
      final fileSize = await copiedFile.length();
      print('Full-res Canon photo stored: $imagePath ($fileSize bytes)');

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

    // Clean up the Canon temp file after we've copied it
    try {
      await file.delete();
    } catch (e) {
      print('Warning: Could not delete Canon temp file: $e');
    }
  }

  /// Save the composited frame as a high-quality PNG to the photos temp
  /// directory so it lives alongside the captured photos.
  ///
  /// Accepts the raw PDF bytes, rasterizes the first page at 300 DPI,
  /// and writes the result as a PNG file. Returns the saved file path.
  Future<String> saveFramePdf(Uint8List pdfBytes) async {
    final currentState = state.value;
    if (currentState == null) {
      throw Exception('State is not available to save frame.');
    }

    // Delete previous frame file if it exists (e.g. user re-generated)
    if (_savedFramePath != null) {
      try {
        final oldFile = File(_savedFramePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
          print('Deleted previous frame file: $_savedFramePath');
        }
      } catch (e) {
        print('Warning: Could not delete previous frame file: $e');
      }
    }

    // Convert PDF to PNG at 300 DPI for full print quality
    Uint8List pngBytes;
    try {
      final pages = Printing.raster(pdfBytes, dpi: 300);
      final firstPage = await pages.first;
      pngBytes = await firstPage.toPng();
      print(
        'Frame PDF rasterized to PNG: '
        '${firstPage.width}×${firstPage.height} px, ${pngBytes.length} bytes',
      );
    } catch (e) {
      print('Warning: PNG conversion failed, saving as PDF fallback: $e');
      // Fallback: save the raw PDF if rasterization fails
      final fallbackName =
          'photostrip_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final fallbackPath = p.join(currentState.tempPath, fallbackName);
      final fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(pdfBytes, flush: true);
      _savedFramePath = fallbackPath;
      return fallbackPath;
    }

    final fileName = 'photostrip_${DateTime.now().millisecondsSinceEpoch}.png';
    final pngPath = p.join(currentState.tempPath, fileName);
    final file = File(pngPath);
    await file.writeAsBytes(pngBytes, flush: true);

    _savedFramePath = pngPath;
    final fileSize = await file.length();
    print('Frame PNG saved: $pngPath ($fileSize bytes)');

    return pngPath;
  }

  /// Get the path to the saved frame file (PNG), if any.
  String? get savedFramePdfPath => _savedFramePath;

  Future<Uint8List> _processImageMinimal(
    Uint8List imageBytes,
    int layoutMode, {
    bool isLandscape = false,
  }) async {
    try {
      return await Isolate.run(() async {
        try {
          final originalImage = img.decodeImage(imageBytes);
          if (originalImage == null) return imageBytes;

          // Determine target aspect ratio based on layout mode and landscape flag
          double targetAspectRatio;
          int targetWidth, targetHeight;

          if (layoutMode == 3) {
            // 3x2 mode: Square 1:1 aspect ratio
            targetAspectRatio = 1.0;
            targetWidth = 600;
            targetHeight = 600;
          } else if (layoutMode == 2) {
            // 2x2 mode: Portrait 5:6 aspect ratio
            targetAspectRatio = 5 / 6;
            targetWidth = 500;
            targetHeight = 600;
          } else if (layoutMode == 4 && isLandscape) {
            // 4x4 landscape mode: Portrait 3:4 aspect ratio (photos will be rotated in frame)
            targetAspectRatio = 3 / 4;
            targetWidth = 450;
            targetHeight = 600;
          } else {
            // 4x4 normal mode: Landscape 4:3 aspect ratio
            targetAspectRatio = 4 / 3;
            targetWidth = 600;
            targetHeight = 450;
          }

          // Only crop if needed, no resize
          img.Image processedImage;
          final currentAspectRatio = originalImage.width / originalImage.height;

          if ((currentAspectRatio - targetAspectRatio).abs() > 0.1) {
            // Significant aspect ratio difference, crop to match
            if (currentAspectRatio > targetAspectRatio) {
              // Image is wider, crop horizontally
              final newWidth = (originalImage.height * targetAspectRatio)
                  .round();
              final cropX = (originalImage.width - newWidth) ~/ 2;
              processedImage = img.copyCrop(
                originalImage,
                x: cropX,
                y: 0,
                width: newWidth,
                height: originalImage.height,
              );
            } else {
              // Image is taller, crop vertically
              final newHeight = (originalImage.width / targetAspectRatio)
                  .round();
              final cropY = (originalImage.height - newHeight) ~/ 2;
              processedImage = img.copyCrop(
                originalImage,
                x: 0,
                y: cropY,
                width: originalImage.width,
                height: newHeight,
              );
            }
          } else {
            // Aspect ratio is close enough, use original
            processedImage = originalImage;
          }

          // Only resize if image is significantly larger than target
          if (processedImage.width > targetWidth * 2 ||
              processedImage.height > targetHeight * 2) {
            processedImage = img.copyResize(
              processedImage,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.nearest, // Fastest interpolation
            );
          }

          return img.encodeJpg(
            processedImage,
            quality: 90, // Higher quality, less processing
          );
        } catch (e) {
          print('Error in minimal image processing: $e');
          return imageBytes; // Return original if processing fails
        }
      });
    } catch (e) {
      print('Error in minimal image processing: $e');
      return imageBytes; // Return original if processing fails
    }
  }

  Future<void> setCaptureCount(int count) async {
    print('setCaptureCount called with count: $count');

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

      // Stop Canon preview recording if active
      try {
        final canonService = ref.read(canonCameraServiceProvider);
        if (currentState.isRecording) {
          await canonService.stopRecordingWithPreviewRetry();
        }
      } catch (e) {
        print('Error stopping Canon recording during clear: $e');
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

      // Clean up processed video files and frame PDFs
      final tempDir = Directory(currentState.tempPath);
      await for (final entity in tempDir.list()) {
        if (entity is File &&
            (entity.path.contains('vhs_processed_') ||
                entity.path.contains('raw_session_') ||
                entity.path.contains('photostrip_'))) {
          try {
            await entity.delete();
            print('Cleaned up file: ${entity.path}');
          } catch (e) {
            print('Error cleaning up file: $e');
          }
        }
      }

      _savedFramePath = null;

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
    final currentState = state.value;
    if (currentState == null) {
      throw Exception("State is not available to apply filters.");
    }

    // Don't use AsyncValue.guard here — it sets state to AsyncLoading which
    // causes the UI to show a full-screen loading spinner instead of the
    // filter screen's own loading overlay.
    try {
      // Process all photos in parallel using Isolate.run for each
      final futures = currentState.photos.map((photo) async {
        final file = File(photo.imagePath);
        if (!await file.exists()) {
          return photo; // Keep original if file doesn't exist
        }

        try {
          // Read image bytes
          final imageBytes = await file.readAsBytes();

          // Process in isolate to avoid blocking UI
          final filteredBytes = await Isolate.run(() {
            final originalImage = img.decodeImage(imageBytes);
            if (originalImage == null) return imageBytes;

            // Apply the filter
            final filteredImage = filterFunction(originalImage);

            // Encode back to JPEG with good quality
            return img.encodeJpg(filteredImage, quality: 92);
          });

          // Generate unique filename
          final fileName =
              'filtered_${DateTime.now().millisecondsSinceEpoch}_${photo.index}.jpg';
          final filteredPath = p.join(currentState.tempPath, fileName);
          final filteredFile = File(filteredPath);

          // Write filtered image (use flush: false for speed)
          await filteredFile.writeAsBytes(filteredBytes, flush: false);

          // Delete old file
          try {
            await file.delete();
          } catch (_) {}

          return photo.copyWith(imagePath: filteredPath);
        } catch (e) {
          print('Error processing photo ${photo.index}: $e');
          return photo; // Keep original on error
        }
      });

      // Wait for all photos to be processed in parallel
      final updatedPhotos = await Future.wait(futures);

      // Update state directly with data, keeping it as AsyncData
      state = AsyncValue.data(
        currentState.copyWith(photos: updatedPhotos.toList()),
      );
    } catch (e) {
      print('Error applying filters: $e');
      // Keep existing state on error rather than transitioning to error state
      rethrow;
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

    print('Total media files: ${mediaFiles.length}');
    return mediaFiles;
  }

  // Get processed video specifically for soft copy upload
  Future<File?> getProcessedVideo() async {
    // Wait for any background VHS processing to complete first
    await ensureVhsProcessingComplete();

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
