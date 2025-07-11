import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:path_provider/path_provider.dart';

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
}

final photoProvider = AsyncNotifierProvider<PhotoNotifier, PhotoState>(
  () => PhotoNotifier(),
);
