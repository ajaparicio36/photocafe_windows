import 'dart:io';
import 'dart:ui' as ui;
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PhotoNotifier extends AsyncNotifier<PhotoState> {
  // Path to the saved frame/photostrip PNG in the photos temp directory
  String? _savedFramePath;

  @override
  Future<PhotoState> build() async {
    final tempPath = await getTemporaryDirectory();
    final photoTempDir = await Directory(
      tempPath.path,
    ).createTemp('bouncy_photos_');
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
    BouncyAttempt? attempt,
    BouncyClip? clip,
    int? replaceIndex,
  }) => ref
      .read(bouncySessionProvider)
      .track(
        _storePhoto(
          filePath,
          layoutMode: layoutMode,
          isLandscape: isLandscape,
          attempt: attempt,
          clip: clip,
          replaceIndex: replaceIndex,
        ),
      );

  Future<void> _storePhoto(
    String filePath, {
    int layoutMode = 4,
    bool isLandscape = false,
    BouncyAttempt? attempt,
    BouncyClip? clip,
    int? replaceIndex,
  }) async {
    final session = ref.read(bouncySessionProvider);
    final generation = session.generation;
    if (attempt != null && (clip == null || clip.problem != null)) {
      throw StateError(clip?.problem ?? 'No live view clip. Retake this shot.');
    }
    final currentState = state.requireValue;
    final previousIndex = replaceIndex == null
        ? -1
        : currentState.photos.indexWhere((p) => p.index == replaceIndex);
    if (replaceIndex != null && previousIndex < 0) {
      throw StateError('Retake shot no longer exists.');
    }
    final ext = p.extension(filePath).isEmpty ? '.jpg' : p.extension(filePath);
    final captureId =
        attempt?.captureId ?? '${DateTime.now().microsecondsSinceEpoch}';
    final imagePath = p.join(
      currentState.tempPath,
      'shot_${captureId}_${attempt?.number ?? 0}$ext',
    );
    final bytes = await File(filePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 64,
      targetHeight: 64,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    await File(filePath).copy(imagePath);
    if (session.generation != generation ||
        (attempt != null && !session.current(attempt))) {
      await File(imagePath).delete();
      throw StateError('Capture session changed.');
    }
    final photos = List<PhotoModel>.from(currentState.photos);
    final index = replaceIndex ?? photos.length;
    final photo = PhotoModel(
      imagePath: imagePath,
      originalPath: imagePath,
      index: index,
      captureId: captureId,
    );
    if (attempt != null) session.accept(attempt, clip!);
    if (replaceIndex == null) {
      photos.add(photo);
    } else {
      photos[previousIndex] = photo;
    }
    state = AsyncValue.data(currentState.copyWith(photos: photos));
  }

  /// Save the composited frame as a high-quality PNG to the photos temp
  /// directory so it lives alongside the captured photos.
  ///
  /// Accepts the raw PDF bytes, rasterizes the first page at 300 DPI,
  /// and writes the result as a PNG file. Returns the saved file path.
  Future<String> saveFramePdf(Uint8List pdfBytes) =>
      ref.read(bouncySessionProvider).track(_saveFramePdf(pdfBytes));
  Future<String> _saveFramePdf(Uint8List pdfBytes) async {
    final session = ref.read(bouncySessionProvider);
    final generation = session.generation;
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
      pngBytes = await rasterFrame(pdfBytes);
    } catch (e) {
      print('Warning: PNG conversion failed, saving as PDF fallback: $e');
      // Fallback: save the raw PDF if rasterization fails
      final fallbackName =
          'photostrip_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final fallbackPath = p.join(currentState.tempPath, fallbackName);
      final fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(pdfBytes, flush: true);
      if (generation != session.generation) {
        throw StateError('Session changed.');
      }
      _savedFramePath = fallbackPath;
      return fallbackPath;
    }

    final fileName = 'photostrip_${DateTime.now().millisecondsSinceEpoch}.png';
    final pngPath = p.join(currentState.tempPath, fileName);
    final file = File(pngPath);
    await file.writeAsBytes(pngBytes, flush: true);

    if (generation != session.generation) throw StateError('Session changed.');
    _savedFramePath = pngPath;
    final fileSize = await file.length();
    print('Frame PNG saved: $pngPath ($fileSize bytes)');

    return pngPath;
  }

  Future<Uint8List> rasterFrame(Uint8List pdfBytes) async {
    final firstPage = await Printing.raster(pdfBytes, dpi: 300).first;
    return firstPage.toPng();
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

          if (layoutMode == 2) {
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
    print('setCaptureCount called with count: $count (but will always use 4)');

    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      if (currentState == null) {
        print(
          'Warning: Photo state was null when setting capture count, creating new state',
        );
        final tempPath = await getTemporaryDirectory();
        final photoTempDir = await Directory(
          tempPath.path,
        ).createTemp('bouncy_photos_');
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

  Future<void>? _resetWork;
  Future<void> clearAllPhotos() =>
      _resetWork ??= _clearAllPhotos().whenComplete(() => _resetWork = null);
  Future<void> _clearAllPhotos() async {
    final currentState = state.value;
    if (currentState == null) return;
    final session = ref.read(bouncySessionProvider);
    session.reset();
    await session.drain();
    await ref.read(bouncyMediaProvider).cancelAndDrain();
    // Each session owns a unique directory; never glob the shared temp folder.
    final temp = await getTemporaryDirectory();
    final next = await Directory(temp.path).createTemp('bouncy_photos_');
    state = AsyncValue.data(
      currentState.copyWith(
        photos: [],
        tempPath: next.path,
        videoPath: null,
        isRecording: false,
      ),
    );
    _savedFramePath = null;
    final owned = Directory(currentState.tempPath);
    if (p.basename(owned.path).startsWith('bouncy_photos_') &&
        await owned.exists()) {
      await owned.delete(recursive: true);
    }
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

  void restoreOriginalPhotos() {
    final current = state.requireValue;
    state = AsyncValue.data(
      current.copyWith(
        photos: [
          for (final photo in current.photos)
            photo.copyWith(imagePath: photo.originalPath ?? photo.imagePath),
        ],
      ),
    );
  }

  Future<void> applyFilters(img.Image Function(img.Image) filterFunction) =>
      ref.read(bouncySessionProvider).track(_applyFilters(filterFunction));
  Future<void> _applyFilters(
    img.Image Function(img.Image) filterFunction,
  ) async {
    final session = ref.read(bouncySessionProvider);
    final generation = session.generation;
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
        final file = File(photo.originalPath ?? photo.imagePath);
        if (!await file.exists()) {
          return photo; // Keep original if file doesn't exist
        }

        try {
          // Read image bytes
          final imageBytes = await file.readAsBytes();

          // Process in isolate to avoid blocking UI
          final filteredBytes = await _filterFullPhoto(
            imageBytes,
            filterFunction,
          );

          // Generate unique filename
          final fileName =
              'filtered_${DateTime.now().millisecondsSinceEpoch}_${photo.index}.jpg';
          final filteredPath = p.join(currentState.tempPath, fileName);
          final filteredFile = File(filteredPath);

          // Write filtered image (use flush: false for speed)
          await filteredFile.writeAsBytes(filteredBytes, flush: false);

          return photo.copyWith(imagePath: filteredPath);
        } catch (e) {
          print('Error processing photo ${photo.index}: $e');
          return photo; // Keep original on error
        }
      });

      // Wait for all photos to be processed in parallel
      final updatedPhotos = await Future.wait(futures);

      if (generation != session.generation) return;
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
      final file = File(photo.originalPath ?? photo.imagePath);
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
}

final photoProvider = AsyncNotifierProvider<PhotoNotifier, PhotoState>(
  PhotoNotifier.new,
);

Future<List<int>> _filterFullPhoto(
  Uint8List imageBytes,
  img.Image Function(img.Image) filter,
) => Isolate.run(() {
  final original = img.decodeImage(imageBytes);
  if (original == null) throw StateError('Original image is unreadable.');
  return img.encodeJpg(filter(original), quality: 92);
});
