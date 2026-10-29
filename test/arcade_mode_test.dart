import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/domain/arcade_flow.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/frame_catalog/presentation/screens/frame_catalog_screen.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FrameCatalog seed;
  late FrameCatalogRepository repository;
  late ProviderContainer container;
  late Uint8List jpeg;
  final runtime = FrameCatalogRuntime.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('arcade-test-');
    final art = img.Image(width: 24, height: 24, numChannels: 4);
    await Directory('${directory.path}/artwork').create();
    await File(
      '${directory.path}/artwork/frame.png',
    ).writeAsBytes(img.encodePng(art));
    jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 64, height: 36)));
    await File('${directory.path}/source.jpg').writeAsBytes(jpeg);
    seed = FrameCatalog(
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
              pixelWidth: 24,
              pixelHeight: 24,
            ),
            slots: const [
              FrameSlot(
                id: 'slot',
                photoIndex: 0,
                left: 10,
                top: 20,
                width: 90,
                height: 80,
              ),
            ],
            enabled: true,
            bundled: false,
          ),
      ],
      enabledProducts: KioskProduct.values.toSet(),
      enabledClassicVariants: ClassicVariant.values.toSet(),
    );
    repository = FrameCatalogRepository(directory: directory, seed: seed);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    container = ProviderContainer(
      overrides: [
        frameCatalogRepositoryProvider.overrideWith((ref) async => repository),
        photoProvider.overrideWith(
          () => _Photos('${directory.path}/bouncy_photos_initial'),
        ),
        printerProvider.overrideWith(_Printer.new),
      ],
    );
    await container.read(frameCatalogProvider.future);
    await container.read(photoProvider.future);
    await container.read(printerProvider.future);
  });
  tearDown(() async {
    await container.read(bouncySessionProvider).drain();
    await container.read(bouncyMediaProvider).cancelAndDrain();
    container.dispose();
    runtime.resetForTesting();
    await directory.delete(recursive: true);
  });

  test(
    'old manifests default off; saved Arcade restores normal menu choices',
    () async {
      final old = seed.toJson()
        ..remove('arcadeEnabled')
        ..remove('arcadeFrameId');
      expect(FrameCatalog.fromJson(old).arcadeEnabled, isFalse);
      final notifier = container.read(frameCatalogProvider.notifier);
      await notifier.setProductEnabled(KioskProduct.classic, false);
      await notifier.setClassicVariantEnabled(ClassicVariant.landscape, false);
      final normal = container.read(frameCatalogProvider).requireValue;
      await notifier.setArcadeFrame('classicLandscape');
      await notifier.setArcadeEnabled(true);
      final loaded = await FrameCatalogRepository(
        directory: directory,
        seed: seed,
      ).load();
      expect(loaded.arcadeEnabled, isTrue);
      expect(loaded.arcadeFrame?.classicVariant, ClassicVariant.landscape);
      expect(KioskProduct.values.where(loaded.isCustomerProductUsable), [
        KioskProduct.classic,
      ]);
      await notifier.setArcadeEnabled(false);
      final off = container.read(frameCatalogProvider).requireValue;
      expect(off.enabledProducts, normal.enabledProducts);
      expect(off.enabledClassicVariants, normal.enabledClassicVariants);
      expect(KioskProduct.values.where(off.isCustomerProductUsable), [
        KioskProduct.keychain,
        KioskProduct.flipbook,
      ]);
    },
  );

  test(
    'selection is required; disabling or removing its frame is rejected',
    () async {
      final notifier = container.read(frameCatalogProvider.notifier);
      await expectLater(
        notifier.setArcadeEnabled(true),
        throwsA(isA<FrameCatalogException>()),
      );
      await expectLater(
        notifier.setArcadeFrame('flipbook'),
        throwsA(isA<FrameCatalogException>()),
      );
      await notifier.setArcadeFrame('classicPortrait');
      await notifier.setArcadeEnabled(true);
      await expectLater(
        notifier.setFrameEnabled('classicPortrait', false),
        throwsA(isA<FrameCatalogException>()),
      );
      final current = container.read(frameCatalogProvider).requireValue;
      expect(
        () => current
            .copyWith(
              templates: current.templates
                  .where((t) => t.id != 'classicPortrait')
                  .toList(),
            )
            .validateAvailability(),
        throwsA(isA<FrameCatalogException>()),
      );
      // A stale externally changed selection stays visible and blocks starts.
      final invalid = FrameCatalog.fromJson({
        ...current.toJson(),
        'arcadeFrameId': 'missing',
      });
      expect(invalid.arcadeEnabled, isTrue);
      expect(invalid.arcadeProblem, isNotNull);
      runtime.replaceCatalog(invalid);
      expect(runtime.beginArcadeSession, throwsA(isA<FrameCatalogException>()));
      expect(invalid.isCustomerProductUsable(KioskProduct.classic), isFalse);
    },
  );

  test(
    'routes freeze accepted frame, guard bypasses and preserve completed print',
    () {
      final selected = seed.copyWith(
        arcadeEnabled: true,
        arcadeFrameId: 'classicLandscape',
      );
      runtime.replaceCatalog(selected);
      for (final path in [
        '/classic/start',
        '/classic/capture',
        '/classic/filter',
        '/classic/organize',
        '/classic/print',
        '/keychain/start',
        '/flipbook/capture',
      ]) {
        expect(runtime.redirect(path), '/');
      }
      expect(
        () => runtime.beginSession(KioskMode.keychain),
        throwsA(isA<FrameCatalogException>()),
      );
      runtime.beginArcadeSession();
      expect(runtime.sessionMode, KioskMode.classicLandscape);
      expect(FrameConstants.availableFrames.map((frame) => frame.id), [
        'classicLandscape',
      ]);
      runtime.replaceCatalog(seed.copyWith(arcadeEnabled: false));
      expect(runtime.sessionArcadeFrame?.id, 'classicLandscape');
      expect(runtime.redirect('/classic/print'), isNull);
      expect(runtime.redirect('/classic/capture'), isNull);
      expect(runtime.redirect('/classic/filter'), '/');
      expect(runtime.redirect('/classic/organize'), '/');
      runtime.endSession();
      expect(runtime.redirect('/classic/start'), isNull);
      expect(runtime.redirect('/classic/capture'), '/classic/start');
      runtime.beginSession(KioskMode.classicPortrait);
      expect(runtime.redirect('/classic/organize'), isNull);
    },
  );

  for (final kind in FrameTemplateKind.values.where(
    (kind) => kind != FrameTemplateKind.flipbook,
  )) {
    for (final count in [1, 2, 3, 4]) {
      test(
        '${kind.name}: $count shots, source order, no filter and native PDF',
        () async {
          final template = seed.byId(kind.name);
          final chosen = template.copyWith(
            slots: [
              template.slots.single.copyWith(photoIndex: count - 1),
              template.slots.single.copyWith(
                id: 'repeat',
                photoIndex: 0,
                top: 110,
              ),
            ],
          );
          runtime.replaceCatalog(
            seed.copyWith(
              templates: [
                for (final item in seed.templates)
                  item.id == chosen.id ? chosen : item,
              ],
              arcadeEnabled: true,
              arcadeFrameId: chosen.id,
            ),
          );
          final session = container.read(bouncySessionProvider);
          session.classicFilterId = 'bw';
          final flow = container.read(arcadeFlowProvider);
          await flow.start();
          expect(
            container.read(photoProvider).requireValue.captureCount,
            count,
          );
          expect(session.captureCount, count);
          expect(session.classicFilterId, 'no_filter');
          final printer = container.read(printerProvider).requireValue;
          expect(
            printer.layoutMode,
            kind == FrameTemplateKind.classicPhotobox ? 2 : 4,
          );
          expect(
            printer.isLandscape,
            kind == FrameTemplateKind.classicLandscape,
          );
          await expectLater(flow.preparePrint(), throwsStateError);
          final clip = validateBouncyImages(
            BouncyClip([BouncyFrame(3000000, jpeg)], 3000000),
          );
          for (var shot = 0; shot < count; shot++) {
            await container
                .read(photoProvider.notifier)
                .addPhotoFromFile(
                  '${directory.path}/source.jpg',
                  attempt: session.attempt('shot$shot'),
                  clip: clip,
                );
          }
          final pdf = await flow.preparePrint();
          expect(utf8.decode(pdf.take(8).toList()), startsWith('%PDF'));
          expect(latin1.decode(pdf), contains('/MediaBox[0 0 297.6 442.56]'));
          expect(
            container
                .read(photoProvider)
                .requireValue
                .photos
                .map((p) => p.index),
            List.generate(count, (i) => i),
          );
          expect(session.valid(List.generate(count, (i) => 'shot$i')), isTrue);
          expect(container.read(classicBouncyFrameProvider), chosen.id);
          if (count == 2 && kind == FrameTemplateKind.classicPortrait) {
            final frames = await container
                .read(bouncyMediaProvider)
                .prepare(
                  photos: container.read(photoProvider).requireValue.photos,
                  selections: [
                    // Reuses the same frozen frame that produced the PDF.
                    KeychainVariantSelection(
                      frameId: chosen.id,
                      filterId: 'no_filter',
                    ),
                  ],
                  classicLayout: layoutTypeForKind(chosen.kind),
                );
            expect(frames.length, 36);
          }
          await container.read(photoProvider.notifier).clearAllPhotos();
          await container.read(photoProvider.notifier).setCaptureCount(4);
          expect(session.captureCount, 4);
        },
      );
    }
  }

  testWidgets(
    'staff setup and home show one Classic start leading directly to capture',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final notifier = container.read(frameCatalogProvider.notifier);
      await tester.runAsync(() async {
        await notifier.setArcadeFrame('classicPortrait');
        await notifier.setArcadeEnabled(true);
      });
      final router = GoRouter(
        refreshListenable: runtime,
        redirect: (_, state) => runtime.redirect(state.uri.path),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AppStartScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const FrameCatalogScreen(),
          ),
          GoRoute(
            path: '/classic/capture',
            builder: (_, _) => const Scaffold(body: Text('Capture reached')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CLASSIC MODE'), findsOneWidget);
      expect(find.text('KEYCHAIN MODE'), findsNothing);
      expect(find.text('FLIPBOOK MODE'), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('CLASSIC MODE'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Capture reached'), findsOneWidget);
      expect(runtime.sessionArcadeFrame?.id, 'classicPortrait');
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Arcade Mode'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('arcade-enabled')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('product-classic')),
            )
            .onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );
}

class _Photos extends PhotoNotifier {
  final String _directory;
  _Photos(this._directory);
  @override
  Future<PhotoState> build() async {
    await Directory(_directory).create();
    return PhotoState(photos: [], tempPath: _directory, captureCount: 4);
  }
}

class _Printer extends PrinterNotifier {
  @override
  Future<PrinterState> build() async => const PrinterState();
  @override
  Future<void> setLayoutMode(int mode) async =>
      state = AsyncData(state.requireValue.copyWith(layoutMode: mode));
  @override
  Future<void> setLandscapeOrientation(bool isLandscape) async =>
      state = AsyncData(state.requireValue.copyWith(isLandscape: isLandscape));
}
