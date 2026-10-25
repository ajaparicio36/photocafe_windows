import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/classic_frame_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/flipbook_frame_factory.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FrameCatalogRepository repository;
  late FrameArtwork artwork;
  late List<PhotoModel> photos;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-render-');
    repository = FrameCatalogRepository(
      directory: directory,
      seed: FrameCatalog(
        templates: [],
        enabledProducts: {},
        enabledClassicVariants: {},
      ),
    );
    await repository.load();
    artwork = await repository.importPng(
      Uint8List.fromList(
        img.encodePng(img.Image(width: 32, height: 48, numChannels: 4)),
      ),
      'transparent.png',
    );
    photos = [];
    for (var index = 0; index < 4; index++) {
      final file = File('${directory.path}/photo-$index.png');
      final image = img.Image(width: 80, height: 60);
      img.fill(
        image,
        color: img.ColorRgb8(
          index == 0 ? 255 : 0,
          index == 1 ? 255 : 0,
          index == 3 ? 255 : 0,
        ),
      );
      await file.writeAsBytes(img.encodePng(image));
      photos.add(
        PhotoModel(imagePath: file.path, index: index, captureId: 'shot$index'),
      );
    }
  });
  tearDown(() async {
    FrameCatalogRuntime.instance.resetForTesting();
    await directory.delete(recursive: true);
  });
  FrameTemplate template(FrameTemplateKind kind) => FrameTemplate(
    id: kind.name,
    name: kind.name,
    revision: 1,
    kind: kind,
    artwork: artwork,
    slots: [
      FrameSlot(
        id: 'first',
        photoIndex: kind == FrameTemplateKind.flipbook ? 0 : 3,
        left: 20,
        top: 20,
        width: 90,
        height: 130,
        rotationDegrees: 23,
      ),
      FrameSlot(
        id: 'repeat',
        photoIndex: kind == FrameTemplateKind.flipbook ? 0 : 1,
        left: 150,
        top: 20,
        width: 90,
        height: 130,
      ),
    ],
    enabled: true,
    bundled: false,
  );

  test(
    'all 25 migrated definitions retain the same raster pixels as their original definitions',
    () async {
      final catalog = await bundledFrameCatalog();
      final sources = [
        for (final photo in photos)
          img.decodePng(await File(photo.imagePath).readAsBytes())!,
      ];
      for (final original in FrameConstants.bundledFrames) {
        final old = original.layouts.values.single;
        final data = await rootBundle.load(old.frameAssetPath);
        final frame = img.decodePng(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        )!;
        final expected = FrameCompositionRenderer.renderDecodedVariant(
          layout: old,
          frame: frame,
          photos: sources,
        );
        final actual = FrameCompositionRenderer.renderDecodedVariant(
          layout: classicDefinition(
            catalog.byId(original.id),
          ).layouts.values.single,
          frame: frame,
          photos: sources,
        );
        expect(actual.getBytes(), expected.getBytes(), reason: original.id);
      }
    },
  );

  test('off-page slots preserve the full source crop before page clipping', () {
    final source = img.Image(width: 100, height: 100);
    for (final pixel in source) {
      pixel.setRgb(pixel.x * 2, 0, 0);
    }
    const layout = FrameLayout(
      type: FrameLayoutType.fourPhotos,
      topOffset: 0,
      frameAssetPath: '',
      leftColumnPositions: [
        FramePhotoPosition(left: -50, top: 100, width: 100, height: 100),
      ],
      rightColumnPositions: [],
    );
    final image = FrameCompositionRenderer.renderDecodedVariant(
      layout: layout,
      frame: img.Image(width: 32, height: 48, numChannels: 4),
      photos: [source, source, source, source],
    );
    expect(
      image.getPixel(0, 250).r,
      100,
    ); // left page edge is halfway through source.
    expect(image.getPixel(100, 250).r, 196);
    expect(image.getPixel(110, 250).g, 255); // white outside the authored slot.
  });

  test(
    'legacy portrait/Photobox fingerprints stay exact for inside-page slots, and off-page crop corrections are explicit',
    () async {
      // Captured from production 9122c57's renderer before the rotation/page-clip
      // correction, with these deterministic gradients and shipped PNG artwork.
      const legacy = <String, int>{
        '4by4_frame_three': 99518110,
        '4by4_frame_six': 3080157482,
        '4by4_frame_twelve': 1404032064,
        '4by4_frame_thirteen': 3277755889,
        '4by4_frame_fourteen': 2234827870,
        '4by4_frame_fifteen': 1917117285,
        '4by4_frame_sixteen': 2013120748,
        '4by4_frame_seventeen': 674699979,
        '4by4_frame_eighteen': 4005511109,
        '4by4_frame_twenty': 4126687046,
        '4by4_frame_twenty_one': 405843494,
        '4by4_frame_twenty_two': 901471806,
        '2by2_frame_one': 3130920242,
        '2by2_frame_two': 1332381456,
        '2by2_frame_three': 100935941,
        '2by2_frame_four': 933464314,
        '2by2_frame_five': 3257261080,
        '2by2_frame_six': 252188256,
        '2by2_frame_seven': 2338864962,
      };
      final sources = [
        for (var i = 0; i < 4; i++)
          img.Image(width: 79 + i * 2, height: 53 + i * 4, numChannels: 4),
      ];
      for (var i = 0; i < sources.length; i++) {
        for (final pixel in sources[i]) {
          pixel.setRgba(
            (pixel.x * 17 + i * 31) % 256,
            pixel.y * 19 % 256,
            (pixel.x + pixel.y) * 7 % 256,
            255,
          );
        }
      }
      final changedPortrait = <String>[], changedPhotobox = <String>[];
      for (final definition in FrameConstants.bundledFrames.where(
        (f) => legacy.containsKey(f.id),
      )) {
        final layout = definition.layouts.values.single;
        final data = await rootBundle.load(layout.frameAssetPath);
        final artwork = img.decodePng(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        )!;
        final image = FrameCompositionRenderer.renderDecodedVariant(
          layout: layout,
          frame: artwork,
          photos: sources,
        );
        var hash = 2166136261;
        for (final byte in image.getBytes()) {
          hash = ((hash ^ byte) * 16777619) & 0xffffffff;
        }
        final overflow =
            [...layout.leftColumnPositions, ...layout.rightColumnPositions].any(
              (p) =>
                  p.left < 0 ||
                  p.top < 0 ||
                  p.left + p.width > FramePdfGeometry.pageWidth ||
                  p.top + p.height > FramePdfGeometry.pageHeight,
            );
        if (overflow) {
          expect(
            hash,
            isNot(legacy[definition.id]),
            reason: '${definition.id} intentional source-crop correction',
          );
          (layout.type == FrameLayoutType.fourPhotos
                  ? changedPortrait
                  : changedPhotobox)
              .add(definition.id);
        } else {
          expect(
            hash,
            legacy[definition.id],
            reason: '${definition.id} unchanged production pixels',
          );
        }
      }
      expect(changedPortrait, hasLength(8));
      expect(changedPhotobox, hasLength(5));
    },
  );

  test(
    'rotated slot edges follow the centered PDF/editor rectangle and clip only at the page',
    () {
      final red = img.Image(width: 80, height: 60);
      img.fill(red, color: img.ColorRgb8(255, 0, 0));
      final clear = img.Image(width: 32, height: 48, numChannels: 4);
      const layout = FrameLayout(
        type: FrameLayoutType.fourPhotos,
        topOffset: 0,
        frameAssetPath: '',
        leftColumnPositions: [
          FramePhotoPosition(
            left: 100,
            top: 100,
            width: 100,
            height: 40,
            rotationDegrees: 90,
          ),
        ],
        rightColumnPositions: [],
      );
      final image = FrameCompositionRenderer.renderDecodedVariant(
        layout: layout,
        frame: clear,
        photos: [red, red, red, red],
      );
      expect(image.getPixel(312, 170).g, 0);
      expect(
        image.getPixel(312, 170).r,
        255,
      ); // above original top, inside rotated bounds.
      expect(
        image.getPixel(220, 250).g,
        255,
      ); // inside original bounds, outside rotated rectangle.
    },
  );

  test(
    'managed artwork reaches both Classic PDF paths and Keychain preview/final isolate',
    () async {
      final portrait = template(FrameTemplateKind.classicPortrait);
      final catalog = FrameCatalog(
        templates: [portrait],
        enabledProducts: {KioskProduct.classic, KioskProduct.keychain},
        enabledClassicVariants: {ClassicVariant.portrait},
      );
      FrameCatalogRuntime.instance.replaceCatalog(catalog);
      FrameCatalogRuntime.instance.beginSession(KioskMode.classicPortrait);
      final definition = FrameConstants.availableFrames.single;
      final widget = ClassicFrameWidget(frameDefinition: definition);
      final layout = definition.layouts.values.single;
      for (final bytes in [
        await widget.generatePdfFromLayout(photos, 4, layout),
        await widget.generatePdfFromLayoutWithRotations(photos, 4, layout, [
          23,
          0,
          0,
          0,
        ]),
      ]) {
        expect(latin1.decode(bytes), contains('/MediaBox[0 0 297.6 442.56]'));
        expect(
          pageContents(bytes).single,
          contains('297.6 0 0 442.56 0 0 cm /I'),
        );
      }
      FrameCatalogRuntime.instance.beginSession(KioskMode.keychain);
      final service = KeychainCompositionService();
      addTearDown(service.dispose);
      final preview = img.decodePng(
        await service.renderVariantPreview(
          selection: KeychainSessionState.initial().variants.first,
          photos: photos,
        ),
      )!;
      expect((preview.width, preview.height), (620, 922));
      final center = preview.getPixel(130, 150);
      expect(center.b, greaterThan(220));
      expect(
        center.r,
        lessThan(20),
      ); // Explicit photoIndex3 survives isolate DTO.
      final output = await service.render(
        session: KeychainSessionState.initial(),
        photos: photos,
      );
      final sheet = img.decodePng(output.sheetPng)!;
      expect((sheet.width, sheet.height), (1240, 1844));
      expect(sheet.getPixel(130, 150).b, greaterThan(220));
      expect(
        latin1.decode(output.sheetPdf),
        contains('/MediaBox[0 0 297.6 442.56]'),
      );
    },
  );

  test(
    'Flipbook managed artwork paints repeated slots from each current sequence image',
    () async {
      final frame = flipbookDefinition(template(FrameTemplateKind.flipbook));
      final bytes = await FlipbookFrameFactory.generatePdfForFrame(frame, [
        FrameModel(path: photos[0].imagePath, index: 0),
        FrameModel(path: photos[1].imagePath, index: 1),
      ]);
      final pages = pageContents(bytes);
      expect(pages, hasLength(25));
      final names = RegExp(
        r'/I\d+ Do',
      ).allMatches(pages.first).map((m) => m.group(0)).toList();
      expect(
        names,
        hasLength(6),
      ); // two photos + overlay on each of two leaves.
      expect(names[0], names[1]);
      expect(names[3], names[4]);
      expect(names[0], isNot(names[3]));
      expect(names[2], names[5]);
      expect(pages.first, contains('0.9205')); // nonzero conjugated rotation.
      final empty = FlipbookFrameFactory.generatePdfForFrame(frame, []);
      await expectLater(empty, throwsStateError);
    },
  );

  test(
    'all Classic variants and four-design Bouncy use managed artwork and explicit photo mapping',
    () async {
      final templates = [
        for (final kind in FrameTemplateKind.values.where(
          (k) => k != FrameTemplateKind.flipbook,
        ))
          template(kind),
      ];
      final catalog = FrameCatalog(
        templates: templates,
        enabledProducts: {KioskProduct.classic, KioskProduct.keychain},
        enabledClassicVariants: ClassicVariant.values.toSet(),
      );
      FrameCatalogRuntime.instance.replaceCatalog(catalog);
      final captures = BouncySession();
      addTearDown(captures.dispose);
      for (var shot = 0; shot < 4; shot++) {
        final jpeg = Uint8List.fromList(
          img.encodeJpg(
            img.decodePng(await File(photos[shot].imagePath).readAsBytes())!,
          ),
        );
        captures.accept(
          captures.attempt('shot$shot'),
          validateBouncyImages(
            BouncyClip([
              for (var i = 0; i <= 30; i++) BouncyFrame(i * 100000, jpeg),
            ], 3000000),
          ),
        );
      }
      final media = BouncyMediaService(captures);
      addTearDown(media.dispose);
      for (final mode in [
        KioskMode.classicPortrait,
        KioskMode.classicLandscape,
        KioskMode.classicPhotobox,
        KioskMode.keychain,
      ]) {
        FrameCatalogRuntime.instance.beginSession(mode);
        final kind = switch (mode) {
          KioskMode.classicLandscape => FrameTemplateKind.classicLandscape,
          KioskMode.classicPhotobox => FrameTemplateKind.classicPhotobox,
          _ => FrameTemplateKind.classicPortrait,
        };
        final selections = [
          for (var i = 0; i < (mode == KioskMode.keychain ? 4 : 1); i++)
            KeychainVariantSelection(frameId: kind.name, filterId: 'no_filter'),
        ];
        final frames = await media.prepare(
          photos: photos,
          selections: selections,
          classicLayout: mode == KioskMode.keychain
              ? null
              : layoutTypeForKind(kind),
        );
        final first = img.decodePng(frames.first)!;
        expect(
          first
              .getPixel(
                mode == KioskMode.keychain ? 130 : 68,
                mode == KioskMode.keychain ? 150 : 88,
              )
              .b,
          greaterThan(220),
          reason: mode.name,
        );
        expect((
          first.width,
          first.height,
        ), mode == KioskMode.keychain ? (620, 922) : (310, 462));
      }
      await media.cancelAndDrain();
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

List<String> pageContents(Uint8List bytes) {
  final text = latin1.decode(bytes);
  final result = <String>[];
  for (final stream in RegExp(
    r'<</Filter/FlateDecode/Length (\d+)>>stream\r?\n',
  ).allMatches(text)) {
    final length = int.parse(stream.group(1)!);
    final decoded = latin1.decode(
      ZLibCodec().decode(bytes.sublist(stream.end, stream.end + length)),
    );
    if (decoded.contains(' cm /I')) result.add(decoded);
  }
  return result;
}
