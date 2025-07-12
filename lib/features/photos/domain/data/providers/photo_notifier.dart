import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PhotoNotifier extends AsyncNotifier<PhotoState> {
  @override
  Future<PhotoState> build() async {
    final tempPath = await getTemporaryDirectory();
    // Create a dedicated subdirectory to avoid conflicts and for easier cleanup.
    final photoTempDir = Directory(p.join(tempPath.path, 'photos'));
    if (!await photoTempDir.exists()) {
      await photoTempDir.create(recursive: true);
    }
    return PhotoState(photos: [], tempPath: photoTempDir.path);
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

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = p.join(currentState.tempPath, fileName);
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

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

      // Delete all photo files from the temporary directory
      for (final photo in currentState.photos) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      return currentState.copyWith(photos: []);
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
}

final photoProvider = AsyncNotifierProvider<PhotoNotifier, PhotoState>(
  () => PhotoNotifier(),
);
