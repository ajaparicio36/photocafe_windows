import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preview cache reuses files, filters, and frame assets', () async {
    final directory = await Directory.systemTemp.createTemp(
      'keychain-preview-cache-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final frameBytes = _solidPng(1200, 1800, 255, 255, 255);
    final photos = await _writePhotos(directory);
    var frameAssetReads = 0;
    final service = KeychainCompositionService(
      loadAsset: (_) async {
        frameAssetReads++;
        return ByteData.sublistView(frameBytes);
      },
    );
    addTearDown(service.dispose);

    final first = await service.renderVariantPreview(
      selection: _selection(frameId: FrameConstants.availableFrames[0].id),
      photos: photos,
    );
    expect(img.decodeImage(first), isNotNull);
    expect(img.decodeImage(first)!.width, 600);
    expect(img.decodeImage(first)!.height, 900);
    expect(frameAssetReads, 1);

    // The source files are no longer readable, proving that the second
    // request uses the cached source/filter result instead of rereading them.
    for (final photo in photos) {
      await File(photo.imagePath).writeAsBytes(const <int>[1, 2, 3]);
    }
    final sameFilter = await service.renderVariantPreview(
      selection: _selection(frameId: FrameConstants.availableFrames[0].id),
      photos: photos,
    );
    expect(img.decodeImage(sameFilter), isNotNull);

    // A new filter still uses the bounded source cache, and a repeated frame
    // uses the derived frame cache.
    final newFilter = await service.renderVariantPreview(
      selection: _selection(
        frameId: FrameConstants.availableFrames[0].id,
        filterId: 'mono_b1',
      ),
      photos: photos,
    );
    expect(img.decodeImage(newFilter), isNotNull);
    expect(frameAssetReads, 1);
  });

  test(
    'full export keeps final geometry through isolated raster work',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'keychain-final-export-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final frameBytes = _solidPng(1200, 1800, 255, 255, 255);
      final photos = await _writePhotos(directory);
      final service = KeychainCompositionService(
        loadAsset: (_) async => ByteData.sublistView(frameBytes),
      );
      addTearDown(service.dispose);

      final frames = FrameConstants.availableFrames;
      final session = KeychainSessionState(
        variants: [
          _selection(frameId: frames[0].id),
          _selection(frameId: frames[1].id, filterId: 'mono_b1'),
          _selection(frameId: frames[2].id, filterId: 'mono_b1'),
          _selection(frameId: frames[0].id),
        ],
      );
      final output = await service.render(session: session, photos: photos);

      expect(output.variantPngs, hasLength(keychainVariantCount));
      for (final variant in output.variantPngs) {
        final decoded = img.decodeImage(variant);
        expect(decoded, isNotNull);
        expect(decoded!.width, 600);
        expect(decoded.height, 900);
      }
      final sheet = img.decodeImage(output.sheetPng);
      expect(sheet, isNotNull);
      expect(sheet!.width, 1200);
      expect(sheet.height, 1800);
      expect(output.sheetPdf, isNotEmpty);
    },
  );

  test(
    'rapid preview requests keep only the newest queued selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'keychain-preview-queue-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final frameBytes = _solidPng(1200, 1800, 255, 255, 255);
      final photos = await _writePhotos(directory);
      final service = KeychainCompositionService(
        loadAsset: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return ByteData.sublistView(frameBytes);
        },
      );
      addTearDown(service.dispose);

      final firstRequest = service.renderVariantPreview(
        selection: _selection(frameId: FrameConstants.availableFrames[0].id),
        photos: photos,
      );
      final supersededRequest = service.renderVariantPreview(
        selection: _selection(frameId: FrameConstants.availableFrames[1].id),
        photos: photos,
      );
      final supersededExpectation = expectLater(
        supersededRequest,
        throwsA(isA<KeychainPreviewCancelledException>()),
      );
      final latestRequest = service.renderVariantPreview(
        selection: _selection(
          frameId: FrameConstants.availableFrames[2].id,
          filterId: 'mono_b1',
        ),
        photos: photos,
      );

      await firstRequest;
      await supersededExpectation;
      final latest = await latestRequest;
      expect(img.decodeImage(latest)!.width, 600);
      expect(img.decodeImage(latest)!.height, 900);
    },
  );

  test('VHS processing is deferred only for Keychain capture', () {
    expect(
      PhotoNotifier.shouldDeferVhsProcessing(
        completionRoute: '/keychain/design',
      ),
      isTrue,
    );
    expect(
      PhotoNotifier.shouldDeferVhsProcessing(
        completionRoute: '/classic/filter',
      ),
      isFalse,
    );
  });
}

KeychainVariantSelection _selection({
  required String frameId,
  String filterId = 'no_filter',
}) {
  return KeychainVariantSelection(frameId: frameId, filterId: filterId);
}

Future<List<PhotoModel>> _writePhotos(Directory directory) async {
  final photos = <PhotoModel>[];
  for (var index = 0; index < keychainVariantCount; index++) {
    final bytes = _solidJpg(2400, 1600, 20 * index, 80, 160);
    final path = '${directory.path}${Platform.pathSeparator}photo_$index.jpg';
    await File(path).writeAsBytes(bytes);
    photos.add(PhotoModel(imagePath: path, index: index));
  }
  return photos;
}

Uint8List _solidPng(int width, int height, int red, int green, int blue) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(red, green, blue));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _solidJpg(int width, int height, int red, int green, int blue) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(red, green, blue));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}
