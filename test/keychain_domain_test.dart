import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/keychain/domain/data/providers/keychain_session_notifier.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/keychain/presentation/screens/keychain_print_screen.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Keychain session always contains four independent selections', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(keychainSessionProvider);
    expect(initial.variants, hasLength(keychainVariantCount));
    expect(
      initial.variants.every(
        (selection) =>
            selection.frameId == FrameConstants.availableFrames.first.id,
      ),
      isTrue,
    );

    final notifier = container.read(keychainSessionProvider.notifier);
    final activeFrames = FrameConstants.availableFrames;
    notifier.setVariantFrame(0, activeFrames.first.id);
    notifier.setVariantFrame(1, activeFrames[1].id);
    notifier.setVariantFilter(1, 'mono_b1');
    notifier.setVariantFilter(2, 'vintage_sepia');
    final updated = container.read(keychainSessionProvider);

    expect(updated.variants[0].frameId, activeFrames.first.id);
    expect(updated.variants[1].frameId, activeFrames[1].id);
    expect(updated.variants[1].filterId, 'mono_b1');
    expect(updated.variants[2].filterId, 'vintage_sepia');
    expect(updated.variants[2], isNot(updated.variants[3]));
    expect(updated.variants[3].filterId, 'no_filter');
    notifier.setDesignIndex(3);
    notifier.enterReview();
    expect(container.read(keychainSessionProvider).isReview, isTrue);
    expect(container.read(keychainSessionProvider).designIndex, 3);
    notifier.returnToDesignFour();
    expect(container.read(keychainSessionProvider).isReview, isFalse);
    expect(container.read(keychainSessionProvider).designIndex, 3);
    expect(
      () => notifier.setVariantFrame(4, activeFrames.first.id),
      throwsRangeError,
    );
    expect(
      () => KeychainSessionState(
        variants: List<KeychainVariantSelection>.filled(
          keychainVariantCount - 1,
          KeychainVariantSelection(
            frameId: activeFrames.first.id,
            filterId: 'no_filter',
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('Keychain catalog exposes every Classic frame layout', () {
    final frames = KeychainFrameCatalog.allClassicFrames;
    expect(frames, isNotEmpty);
    expect(
      frames.map((frame) => frame.id),
      orderedEquals(FrameConstants.availableFrames.map((frame) => frame.id)),
    );
    expect(frames.first.id, FrameConstants.availableFrames.first.id);
    expect(frames.every((frame) => frame.layouts.isNotEmpty), isTrue);
  });

  test('Keychain print cut control has one disabled-by-default contract', () {
    expect(KeychainPrintScreen.defaultCut, isFalse);
    expect(KeychainPrintScreen.cutControlTitle, 'Cut sheet after printing');
    expect(
      KeychainPrintScreen.cutControlDescription,
      contains('four-up sheet'),
    );

    const classicPanel = PrintActionPanel(
      isPrinting: false,
      splitStrips: true,
      onSplitStripsChanged: _noopBool,
      onPrint: _noopInt,
    );
    expect(
      classicPanel.cutControlTitle,
      PrintActionPanel.defaultCutControlTitle,
    );
    expect(
      classicPanel.cutControlDescription,
      PrintActionPanel.defaultCutControlDescription,
    );
  });

  test('Keychain sheet PNG and PDF preserve fixed geometry', () async {
    final colors = [
      const [255, 0, 0],
      const [0, 255, 0],
      const [0, 0, 255],
      const [255, 255, 0],
    ];
    final variants = <Uint8List>[];
    for (final color in colors) {
      final image = img.Image(width: 600, height: 900);
      img.fill(image, color: img.ColorRgb8(color[0], color[1], color[2]));
      variants.add(Uint8List.fromList(img.encodePng(image)));
    }

    final sheetBytes = FrameCompositionRenderer.generateKeychainSheetPng(
      variantPngs: variants,
    );
    final sheet = img.decodeImage(sheetBytes);
    expect(sheet, isNotNull);
    expect(sheet!.width, 1200);
    expect(sheet.height, 1800);
    expect(sheet.getPixel(10, 10).r, 255);
    expect(sheet.getPixel(610, 10).g, 255);
    expect(sheet.getPixel(10, 910).b, 255);
    expect(sheet.getPixel(610, 910).r, 255);

    final pdfBytes = await FrameCompositionRenderer.generateKeychainSheetPdf(
      variantPngs: variants,
    );
    expect(pdfBytes, isNotEmpty);
    expect(
      FramePdfGeometry.pageFormat.width,
      closeTo(FramePdfGeometry.pageWidth, 0.001),
    );
    expect(
      FramePdfGeometry.pageFormat.height,
      closeTo(FramePdfGeometry.pageHeight, 0.001),
    );
    expect(FramePdfGeometry.sheetContentLeft, FramePdfGeometry.bleedPoints);
    expect(FramePdfGeometry.sheetContentTop, FramePdfGeometry.bleedPoints);
    expect(FramePdfGeometry.sheetContentWidth, FramePdfGeometry.trimWidth);
    expect(FramePdfGeometry.sheetContentHeight, FramePdfGeometry.trimHeight);
  });

  test('Renderer rejects any variant count other than four', () {
    expect(
      () => FrameCompositionRenderer.generateKeychainSheetPng(
        variantPngs: const [],
      ),
      throwsArgumentError,
    );
  });

  test('one complete Keychain composition is exactly 600 by 900 PNG', () async {
    final frame = img.Image(width: 1200, height: 1800);
    img.fill(frame, color: img.ColorRgba8(255, 255, 255, 255));
    final frameBytes = Uint8List.fromList(img.encodePng(frame));
    final photos = <Uint8List>[];
    for (var index = 0; index < keychainVariantCount; index++) {
      final photo = img.Image(width: 40, height: 40);
      img.fill(photo, color: img.ColorRgb8(index * 40, 80, 160));
      photos.add(Uint8List.fromList(img.encodeJpg(photo)));
    }

    final png = await FrameCompositionRenderer.renderKeychainVariantPng(
      input: KeychainCompositionInput(
        layout: FrameConstants.classicFourPhotoLayout,
        frameBytes: frameBytes,
        photoBytes: photos,
      ),
    );
    final decoded = img.decodeImage(png);
    expect(decoded, isNotNull);
    expect(decoded!.width, 600);
    expect(decoded.height, 900);
  });

  test(
    'transparent frame keeps a boundary slot inside adjusted page bounds',
    () async {
      final transparentFrame = img.Image(
        width: 1200,
        height: 1800,
        numChannels: 4,
      );
      img.fill(transparentFrame, color: img.ColorRgba8(0, 0, 0, 0));
      final frameBytes = Uint8List.fromList(img.encodePng(transparentFrame));
      final redPhoto = img.Image(width: 40, height: 40);
      img.fill(redPhoto, color: img.ColorRgb8(255, 0, 0));
      final redPhotoBytes = Uint8List.fromList(img.encodePng(redPhoto));
      final layout = FrameLayout(
        type: FrameLayoutType.fourPhotos,
        leftColumnPositions: [
          FramePhotoPosition(
            left: FramePdfGeometry.pageWidth - 12,
            top: FramePdfGeometry.pageHeight - 12,
            width: 12,
            height: 12,
          ),
        ],
        rightColumnPositions: const [],
        topOffset: 0,
        frameAssetPath: 'unused-in-byte-renderer',
      );

      final png = await FrameCompositionRenderer.renderKeychainVariantPng(
        input: KeychainCompositionInput(
          layout: layout,
          frameBytes: frameBytes,
          photoBytes: [
            redPhotoBytes,
            redPhotoBytes,
            redPhotoBytes,
            redPhotoBytes,
          ],
        ),
      );
      final decoded = img.decodeImage(png);
      expect(decoded, isNotNull);
      final scale = 600 / FramePdfGeometry.pageWidth;
      final expectedLeft = ((FramePdfGeometry.pageWidth - 12) * scale).round();
      final expectedTop = ((FramePdfGeometry.pageHeight - 12) * scale).round();
      expect(decoded!.getPixel(expectedLeft + 1, expectedTop + 1).r, 255);
      expect(decoded.getPixel(599, 899).r, 255);
    },
  );

  test('composition service reuses originals without mutating them', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'keychain-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final frame = img.Image(width: 1200, height: 1800);
    img.fill(frame, color: img.ColorRgba8(255, 255, 255, 255));
    final frameBytes = Uint8List.fromList(img.encodePng(frame));
    final photos = <PhotoModel>[];
    final originalBytes = <Uint8List>[];
    for (var index = 0; index < keychainVariantCount; index++) {
      final photo = img.Image(width: 40, height: 40);
      img.fill(photo, color: img.ColorRgb8(index * 40, 80, 160));
      final bytes = Uint8List.fromList(img.encodeJpg(photo));
      originalBytes.add(bytes);
      final path = '${tempDirectory.path}\\original_$index.jpg';
      await File(path).writeAsBytes(bytes);
      photos.add(PhotoModel(imagePath: path, index: index));
    }

    final activeFrames = FrameConstants.availableFrames;
    final session = KeychainSessionState(
      variants: [
        KeychainVariantSelection(
          frameId: activeFrames[0].id,
          filterId: 'no_filter',
        ),
        KeychainVariantSelection(
          frameId: activeFrames[1].id,
          filterId: 'mono_b1',
        ),
        KeychainVariantSelection(
          frameId: activeFrames[2].id,
          filterId: 'vintage_sepia',
        ),
        KeychainVariantSelection(
          frameId: activeFrames[3].id,
          filterId: 'photobooth',
        ),
      ],
    );
    final service = KeychainCompositionService(
      loadAsset: (assetPath) async => ByteData.sublistView(frameBytes),
    );
    final preview = await service.renderVariant(
      selection: session.variants[1],
      photos: photos,
    );
    expect(img.decodeImage(preview)?.width, 600);
    expect(img.decodeImage(preview)?.height, 900);
    final output = await service.render(session: session, photos: photos);

    expect(output.variantPngs, hasLength(keychainVariantCount));
    expect(img.decodeImage(output.sheetPng)?.width, 1200);
    expect(output.selections, session.variants);
    expect(output.selections[0].frameId, session.variants[0].frameId);
    expect(output.selections[1].filterId, session.variants[1].filterId);
    for (var index = 0; index < photos.length; index++) {
      expect(
        await File(photos[index].imagePath).readAsBytes(),
        originalBytes[index],
      );
    }

    final mediaBundle = await output.persist(tempDirectory.path);
    expect(mediaBundle.variantFiles, hasLength(keychainVariantCount));
    expect(
      mediaBundle.variantFiles.map((file) => p.basename(file.path)),
      orderedEquals([
        'keychain_variant_1.png',
        'keychain_variant_2.png',
        'keychain_variant_3.png',
        'keychain_variant_4.png',
      ]),
    );
    expect(p.basename(mediaBundle.sheetFile.path), 'keychain_sheet.png');
  });
}

void _noopBool(bool _) {}

void _noopInt(int _) {}
