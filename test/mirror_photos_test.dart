import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/classic_frame_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_artwork_loader.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/keychain/presentation/screens/keychain_design_screen.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/widgets/mirror_photos_switch.dart';
import 'support/headless_pdf_rasterizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final runtime = FrameCatalogRuntime.instance;
  late Directory directory;
  late FrameCatalog catalog;
  late img.Image source, artwork;
  late List<PhotoModel> photos;
  setUpAll(() async {
    await (FontLoader('SpaceMono')
          ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf')))
        .load();
    await (FontLoader('RubikMonoOne')
          ..addFont(rootBundle.load('assets/fonts/RubikMonoOne-Regular.ttf')))
        .load();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bouncy_photos_mirror_');
    source = img.Image(width: 81, height: 61);
    for (final pixel in source) {
      pixel.setRgb(
        pixel.x < 40 ? 220 : 20,
        pixel.y < 30 ? 60 : 190,
        pixel.x < 40 ? 20 : 220,
      );
    }
    artwork = img.Image(width: 620, height: 922, numChannels: 4);
    img.fillRect(
      artwork,
      x1: 0,
      y1: 0,
      x2: 35,
      y2: 45,
      color: img.ColorRgba8(0, 230, 0, 255),
    );
    await Directory('${directory.path}/artwork').create();
    await File(
      '${directory.path}/artwork/frame.png',
    ).writeAsBytes(img.encodePng(artwork));
    photos = [];
    for (var i = 0; i < 4; i++) {
      final file = await File(
        '${directory.path}/source$i.png',
      ).writeAsBytes(img.encodePng(source));
      photos.add(
        PhotoModel(
          imagePath: file.path,
          originalPath: file.path,
          index: i,
          captureId: 'shot$i',
        ),
      );
    }
    catalog = FrameCatalog(
      templates: [
        for (final kind in FrameTemplateKind.values)
          FrameTemplate(
            id: kind.name,
            name: kind.name,
            revision: 1,
            kind: kind,
            artwork: const FrameArtwork(
              path: 'artwork/frame.png',
              isBundled: false,
              pixelWidth: 620,
              pixelHeight: 922,
            ),
            slots: const [
              FrameSlot(
                id: 'one',
                photoIndex: 0,
                left: 20,
                top: 30,
                width: 100,
                height: 80,
              ),
              FrameSlot(
                id: 'rotated',
                photoIndex: 0,
                left: 155,
                top: 150,
                width: 80,
                height: 100,
                rotationDegrees: 31,
              ),
              FrameSlot(
                id: 'edge',
                photoIndex: 0,
                left: -25,
                top: 300,
                width: 80,
                height: 65,
                rotationDegrees: -23,
              ),
            ],
            enabled: true,
            bundled: false,
          ),
      ],
      enabledProducts: KioskProduct.values.toSet(),
      enabledClassicVariants: ClassicVariant.values.toSet(),
    );
    FrameArtworkLoader.catalogDirectory = directory;
    runtime.replaceCatalog(catalog);
    runtime.beginSession(KioskMode.classicPortrait);
  });
  tearDown(() async {
    runtime.resetForTesting();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'default persists, old catalogs remain OFF, and customer choices are frozen per session',
    () async {
      final old = catalog.toJson()..remove('mirrorPhotosByDefault');
      expect(FrameCatalog.fromJson(old).mirrorPhotosByDefault, isFalse);
      final repository = FrameCatalogRepository(
        directory: directory,
        seed: catalog,
      );
      final container = ProviderContainer(
        overrides: [
          frameCatalogRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(frameCatalogProvider.future);
      runtime.beginSession(KioskMode.classicPortrait);
      await container
          .read(frameCatalogProvider.notifier)
          .setMirrorPhotosByDefault(true);
      expect(runtime.sessionMirrorPhotos, isFalse);
      expect(
        (await FrameCatalogRepository(
          directory: directory,
          seed: catalog,
        ).load()).mirrorPhotosByDefault,
        isTrue,
      );
      runtime.beginSession(KioskMode.keychain);
      expect(runtime.sessionMirrorPhotos, isTrue);
      final revision = runtime.compositionRevision;
      runtime.setSessionMirrorPhotos(false);
      runtime.setSessionMirrorPhotos(true);
      expect(runtime.compositionRevision, revision + 2);
      runtime.replaceCatalog(catalog);
      expect(runtime.sessionMirrorPhotos, isTrue);
      runtime.beginSession(KioskMode.flipbook);
      runtime.setSessionMirrorPhotos(true);
      expect(runtime.sessionMirrorPhotos, isFalse);
      runtime.replaceCatalog(
        catalog.copyWith(
          mirrorPhotosByDefault: true,
          arcadeEnabled: true,
          arcadeFrameId: 'classicPortrait',
        ),
      );
      runtime.beginArcadeSession();
      expect(runtime.sessionMirrorPhotos, isTrue);
      runtime.endSession();
      expect(runtime.sessionMirrorPhotos, isFalse);
    },
  );

  test(
    'raster mirrors upright source pixels before odd cover crops and signed rotations, preserving artwork and filters',
    () {
      final layout = classicDefinition(
        catalog.templates.first,
      ).layouts.values.single;
      for (final orientation in [1, 6]) {
        final input = img.Image.from(source)
          ..exif.imageIfd.orientation = orientation;
        final originalBytes = Uint8List.fromList(input.getBytes());
        for (final filter in FilterConstants.filterDefinitions) {
          final filtered = filter.applyFilter(
            img.bakeOrientation(img.Image.from(input)),
          );
          final expected = FrameCompositionRenderer.renderDecodedVariant(
            layout: layout,
            frame: artwork,
            photos: List.filled(4, img.flipHorizontal(filtered)),
          );
          final actual = FrameCompositionRenderer.renderDecodedVariant(
            layout: layout,
            frame: artwork,
            photos: List.filled(4, input),
            filterId: filter.id,
            mirrorPhotos: true,
          );
          expect(
            actual.getBytes(),
            expected.getBytes(),
            reason: '${filter.id}, EXIF $orientation',
          );
          expect(actual.getPixel(10, 10).g, 230);
          expect(actual.getPixel(600, 10).g, 255);
          expect(input.getBytes(), originalBytes);
        }
      }
    },
  );

  test(
    'Classic PDF pixels reflect only photos, remain reversible, and match slot rotation for EXIF images',
    () async {
      final rasterizer = HeadlessPdfRasterizer();
      final definition = classicDefinition(catalog.templates.first);
      final widget = ClassicFrameWidget(frameDefinition: definition);
      final layout = definition.layouts.values.single;
      for (final orientation in [1, 6]) {
        final oriented = img.Image.from(source)
          ..exif.imageIfd.orientation = orientation;
        final jpeg = img.encodeJpg(oriented, quality: 100);
        final file = await File(
          '${directory.path}/oriented.jpg',
        ).writeAsBytes(jpeg);
        final current = [
          for (final photo in photos) photo.copyWith(imagePath: file.path),
        ];
        runtime.setSessionMirrorPhotos(false);
        final normal = rasterizer.render(
          await widget.generatePdfFromLayout(current, 4, layout),
        );
        runtime.setSessionMirrorPhotos(true);
        final mirrored = rasterizer.render(
          await widget.generatePdfFromLayout(current, 4, layout),
        );
        final rotated = rasterizer.render(
          await widget.generatePdfFromLayoutWithRotations(current, 4, layout, [
            0,
            0,
            0,
            0,
          ]),
        );
        expect(rotated.getBytes(), mirrored.getBytes());
        final expectedSource = img.flipHorizontal(
          img.bakeOrientation(img.decodeJpg(jpeg)!),
        );
        final expectedFile = await File(
          '${directory.path}/expected.png',
        ).writeAsBytes(img.encodePng(expectedSource));
        runtime.setSessionMirrorPhotos(false);
        final expected = rasterizer.render(
          await widget.generatePdfFromLayout(
            [
              for (final photo in photos)
                photo.copyWith(imagePath: expectedFile.path),
            ],
            4,
            layout,
          ),
        );
        // PNG and embedded JPEG interpolation can vary at edges; interior colors
        // and the independent rotated source composition must agree closely.
        var differences = 0;
        for (var y = 0; y < mirrored.height; y += 3) {
          for (var x = 0; x < mirrored.width; x += 3) {
            final a = mirrored.getPixel(x, y), b = expected.getPixel(x, y);
            if ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs() >
                35) {
              differences++;
            }
          }
        }
        expect(differences, lessThan(150), reason: 'EXIF $orientation');
        expect(mirrored.getBytes(), isNot(normal.getBytes()));
        expect(mirrored.getPixel(10, 10).g, 230);
        final restored = rasterizer.render(
          await widget.generatePdfFromLayout(current, 4, layout),
        );
        expect(restored.getBytes(), normal.getBytes());
        expect(await file.readAsBytes(), jpeg);
      }
    },
    skip: !HeadlessPdfRasterizer.available
        ? 'Build Windows once to supply the printing plugin PDFium.'
        : false,
  );

  test(
    'Keychain preview cache and four-up output mirror every design without changing originals',
    () async {
      runtime.beginSession(KioskMode.keychain);
      final service = KeychainCompositionService();
      addTearDown(service.dispose);
      final selection = KeychainSessionState.initial().variants.first;
      final normal = await service.renderVariantPreview(
        selection: selection,
        photos: photos,
      );
      final mirrored = await service.renderVariantPreview(
        selection: selection,
        photos: photos,
        mirrorPhotos: true,
      );
      expect(mirrored, isNot(normal));
      expect(
        await service.renderVariantPreview(
          selection: selection,
          photos: photos,
        ),
        normal,
      );
      final output = await service.render(
        session: KeychainSessionState.initial(),
        photos: photos,
        mirrorPhotos: true,
      );
      final tile = img.decodePng(output.variantPngs.first)!;
      expect(tile.getPixel(65, 100).b, greaterThan(200));
      expect(tile.getPixel(225, 100).r, greaterThan(200));
      final sheet = img.decodePng(output.sheetPng)!;
      for (var i = 0; i < 4; i++) {
        expect(
          sheet.getPixel((i % 2) * 620 + 65, (i ~/ 2) * 922 + 100).b,
          greaterThan(200),
        );
        expect(sheet.getPixel((i % 2) * 620 + 10, (i ~/ 2) * 922 + 10).g, 230);
      }
      if (HeadlessPdfRasterizer.available) {
        final pdf = HeadlessPdfRasterizer().render(
          output.sheetPdf,
          width: 1240,
          height: 1844,
        );
        expect(pdf.getPixel(65, 100).b, greaterThan(200));
        expect(pdf.getPixel(685, 1022).b, greaterThan(200));
      }
      expect(
        await File(photos.first.imagePath).readAsBytes(),
        img.encodePng(source),
      );
    },
  );

  test(
    'Bouncy preparation snapshots mirroring, rejects stale export, and cancels on/off/on work',
    () async {
      final session = BouncySession();
      final media = BouncyMediaService(session, encoders: const ['libx264']);
      addTearDown(session.dispose);
      addTearDown(media.dispose);
      final jpeg = Uint8List.fromList(img.encodeJpg(source, quality: 100));
      for (var i = 0; i < 4; i++) {
        session.accept(
          session.attempt('shot$i'),
          validateBouncyImages(
            BouncyClip([
              for (var tick = 0; tick <= 30; tick++)
                BouncyFrame(tick * 100000, jpeg),
            ], 3000000),
          ),
        );
      }
      final definition = classicDefinition(catalog.templates.first);
      final selection = KeychainVariantSelection(
        frameId: definition.id,
        filterId: 'no_filter',
      );
      final normal = await media.prepare(
        photos: photos,
        selections: [selection],
        classicLayout: definition.layouts.keys.single,
      );
      runtime.setSessionMirrorPhotos(true);
      await expectLater(media.export(), throwsStateError);
      final mirrored = await media.prepare(
        photos: photos,
        selections: [selection],
        classicLayout: definition.layouts.keys.single,
      );
      expect(mirrored.first, isNot(normal.first));
      expect(
        img.decodePng(mirrored.first)!.getPixel(33, 50).b,
        greaterThan(190),
      );
      final mp4 = await media.export();
      final sample = '${directory.path}/motion.png';
      final decoded = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-i',
        mp4,
        '-frames:v',
        '1',
        sample,
      ]);
      expect(decoded.exitCode, 0, reason: '${decoded.stderr}');
      final motion = img.decodePng(await File(sample).readAsBytes())!;
      expect((motion.width, motion.height), (620, 922));
      expect(motion.getPixel(65, 100).b, greaterThan(190));
      expect(motion.getPixel(10, 10).g, greaterThan(210));
      final stale = media.prepare(
        photos: photos,
        selections: [selection],
        classicLayout: definition.layouts.keys.single,
      );
      final rejected = expectLater(stale, throwsStateError);
      runtime.setSessionMirrorPhotos(false);
      runtime.setSessionMirrorPhotos(true);
      await rejected;
      await media.cancelAndDrain();
    },
  );

  test(
    'individual soft copies mirror native EXIF-normalized originals once, cache safely and reject stale work',
    () async {
      final oriented = img.Image.from(source)..exif.imageIfd.orientation = 6;
      final original = Uint8List.fromList(
        img.encodeJpg(oriented, quality: 100),
      );
      final file = await File(
        '${directory.path}/original.jpg',
      ).writeAsBytes(original);
      final captured = [
        for (final photo in photos) photo.copyWith(originalPath: file.path),
      ];
      final container = ProviderContainer(
        overrides: [
          photoProvider.overrideWith(() => _Photos(directory.path, captured)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(photoProvider.future);
      final notifier = container.read(photoProvider.notifier);
      expect(
        await (await notifier.getAllMediaFiles()).first.readAsBytes(),
        original,
      );
      runtime.setSessionMirrorPhotos(true);
      final files = await notifier.getAllMediaFiles();
      final bytes = await files.first.readAsBytes();
      final actual = img.decodeJpg(bytes)!;
      final expected = img.flipHorizontal(
        img.bakeOrientation(img.decodeJpg(original)!),
      );
      expect((actual.width, actual.height), (61, 81));
      for (final point in [(10, 10), (50, 70)]) {
        final a = actual.getPixel(point.$1, point.$2),
            b = expected.getPixel(point.$1, point.$2);
        expect(
          (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs(),
          lessThan(15),
        );
      }
      final modified = await files.first.lastModified();
      expect(
        await (await notifier.getAllMediaFiles()).first.lastModified(),
        modified,
      );
      expect(await file.readAsBytes(), original);
      runtime.setSessionMirrorPhotos(false);
      expect(
        await (await notifier.getAllMediaFiles()).first.readAsBytes(),
        original,
      );
      runtime.setSessionMirrorPhotos(true);
      final stale = notifier.getAllMediaFiles();
      final rejected = expectLater(stale, throwsStateError);
      runtime.setSessionMirrorPhotos(false);
      runtime.setSessionMirrorPhotos(true);
      await rejected;
      expect(
        await (await notifier.getAllMediaFiles()).first.readAsBytes(),
        bytes,
      );
      expect(
        await Directory('${directory.path}/mirrored_downloads').list().length,
        4,
      );
    },
  );

  testWidgets(
    'shared customer switch is reversible, keyboard accessible and disabled during output',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MirrorPhotosSwitch(keychain: true)),
          ),
        ),
      );
      expect(find.text('All photos in all four designs'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(runtime.sessionMirrorPhotos, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(runtime.sessionMirrorPhotos, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(runtime.sessionMirrorPhotos, isTrue);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MirrorPhotosSwitch(enabled: false)),
          ),
        ),
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'reset drains queued download work before deleting its owned directory',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path,
          );
      final container = ProviderContainer(
        overrides: [
          photoProvider.overrideWith(() => _Photos(directory.path, photos)),
        ],
      );
      await container.read(photoProvider.future);
      final notifier = container.read(photoProvider.notifier);
      runtime.setSessionMirrorPhotos(true);
      final stale = notifier.getAllMediaFiles();
      final rejected = expectLater(stale, throwsStateError);
      await notifier.clearAllPhotos();
      await rejected;
      final next = container.read(photoProvider).requireValue;
      expect(await directory.exists(), isFalse);
      expect(next.photos, isEmpty);
      expect(
        await Directory('${next.tempPath}/mirrored_downloads').exists(),
        isFalse,
      );
      container.dispose();
      await Directory(next.tempPath).delete(recursive: true);
    },
  );

  testWidgets(
    'Keychain shows one global mirror choice across designs at kiosk size',
    (tester) async {
      runtime.beginSession(KioskMode.keychain);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          photoProvider.overrideWith(() => _Photos(directory.path, photos)),
        ],
      );
      await container.read(photoProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KeychainDesignScreen()),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('mirror-photos')), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Design 2'));
      await tester.pump();
      expect(runtime.sessionMirrorPhotos, isTrue);
      expect(runtime.catalog!.mirrorPhotosByDefault, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await container.read(bouncySessionProvider).drain();
      container.dispose();
    },
  );
}

class _Photos extends PhotoNotifier {
  final String _directory;
  final List<PhotoModel> _photos;
  _Photos(this._directory, this._photos);
  @override
  Future<PhotoState> build() async => PhotoState(
    photos: _photos,
    tempPath: _directory,
    captureCount: 4,
    isRecording: false,
    videoPath: null,
  );
}
