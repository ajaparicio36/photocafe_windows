import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_artwork_loader.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FrameCatalog seed;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('frame-catalog-');
    const art = FrameArtwork(
      path: 'assets/frames/frame12.png',
      isBundled: true,
      pixelWidth: 1240,
      pixelHeight: 1844,
    );
    seed = FrameCatalog(
      templates: [
        for (final kind in FrameTemplateKind.values)
          FrameTemplate(
            id: kind.name,
            name: kind.name,
            revision: 1,
            kind: kind,
            artwork: art,
            slots: const [
              FrameSlot(
                id: 'one',
                photoIndex: 0,
                left: -10,
                top: 20,
                width: 90,
                height: 130,
                rotationDegrees: -90,
              ),
            ],
            enabled: true,
            bundled: true,
          ),
      ],
      enabledProducts: KioskProduct.values.toSet(),
      enabledClassicVariants: ClassicVariant.values.toSet(),
    );
  });
  tearDown(() async {
    FrameCatalogRuntime.instance.resetForTesting();
    await directory.delete(recursive: true);
  });

  test(
    'bundled catalog preserves all active modes and exact signed geometry',
    () async {
      final real = await bundledFrameCatalog();
      expect(
        real.templates.where(
          (t) => t.enabled && t.kind != FrameTemplateKind.flipbook,
        ),
        hasLength(25),
      );
      expect(
        real.templates.where((t) => t.kind == FrameTemplateKind.flipbook),
        hasLength(6),
      );
      expect(real.templates.where((t) => !t.enabled), hasLength(10));
      for (final mode in KioskMode.values) {
        expect(real.isModeUsable(mode), isTrue);
      }
      expect(
        real
            .customerFrames(KioskMode.keychain)
            .every((t) => t.kind == FrameTemplateKind.classicPortrait),
        isTrue,
      );
      for (final original in FrameConstants.bundledFrames) {
        final migrated = classicDefinition(
          real.byId(original.id),
        ).layouts.values.single;
        final positions = [
          ...original.layouts.values.single.leftColumnPositions,
          ...original.layouts.values.single.rightColumnPositions,
        ];
        expect(
          migrated.frameAssetPath,
          original.layouts.values.single.frameAssetPath,
        );
        for (var i = 0; i < positions.length; i++) {
          final actual = migrated.leftColumnPositions[i],
              expected = positions[i];
          expect(
            [
              actual.left,
              actual.top,
              actual.width,
              actual.height,
              actual.rotationDegrees,
            ],
            [
              expected.left,
              expected.top,
              expected.width,
              expected.height,
              expected.rotationDegrees,
            ],
          );
        }
      }
      final landscape = real.byId('landscape_frame_one');
      expect(landscape.slots.first.top, -10);
      expect(landscape.slots.first.rotationDegrees, -90);
    },
  );

  test(
    'round trip keeps separate product/variant choices and rejects invalid geometry',
    () {
      final off = seed.copyWith(
        enabledProducts: {KioskProduct.keychain},
        enabledClassicVariants: {ClassicVariant.landscape},
      );
      final result = FrameCatalog.fromJson(
        jsonDecode(jsonEncode(off.toJson())),
      );
      expect(result.enabledClassicVariants, {ClassicVariant.landscape});
      expect(result.enabledProducts, {KioskProduct.keychain});
      expect(
        () => off.templates.first
            .copyWith(
              slots: [
                off.templates.first.slots.first.copyWith(width: double.nan),
              ],
            )
            .validate(),
        throwsA(isA<FrameCatalogException>()),
      );
      expect(
        () => seed.copyWith(enabledProducts: {}).validateAvailability(),
        throwsA(isA<FrameCatalogException>()),
      );
      expect(
        () => seed.templates.last
            .copyWith(
              slots: [seed.templates.last.slots.first.copyWith(photoIndex: 1)],
            )
            .validate(),
        throwsA(isA<FrameCatalogException>()),
      );
    },
  );

  test(
    'serialized concurrent mutations retain both updates and stale edits fail',
    () async {
      final repository = FrameCatalogRepository(
        directory: directory,
        seed: seed,
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
      final notifier = container.read(frameCatalogProvider.notifier);
      await Future.wait([
        notifier.setProductEnabled(KioskProduct.classic, false),
        notifier.setClassicVariantEnabled(ClassicVariant.landscape, false),
      ]);
      final current = container.read(frameCatalogProvider).requireValue;
      expect(current.enabledProducts.contains(KioskProduct.classic), isFalse);
      expect(
        current.enabledClassicVariants.contains(ClassicVariant.landscape),
        isFalse,
      );
      final stale = current.templates.first;
      await notifier.saveTemplate(stale.copyWith(name: 'Edited'));
      await expectLater(
        notifier.saveTemplate(stale.copyWith(name: 'Old draft')),
        throwsA(isA<FrameCatalogException>()),
      );
      expect(
        container.read(frameCatalogProvider).requireValue.templates.first.name,
        'Edited',
      );
      final disk = await FrameCatalogRepository(
        directory: directory,
        seed: seed,
      ).load();
      expect(disk.templates.first.name, 'Edited');
      expect(
        disk.enabledClassicVariants.contains(ClassicVariant.landscape),
        isFalse,
      );
      await notifier.setProductEnabled(KioskProduct.classic, true);
      expect(
        container
            .read(frameCatalogProvider)
            .requireValue
            .enabledClassicVariants
            .contains(ClassicVariant.landscape),
        isFalse,
      );
      final otherApp = FrameCatalogRepository(directory: directory, seed: seed);
      final otherCatalog = await otherApp.load();
      await otherApp.save(
        otherCatalog.copyWith(
          templates: [
            for (final t in otherCatalog.templates)
              if (t.id == stale.id)
                t.copyWith(name: 'Other app', revision: t.revision + 1)
              else
                t,
          ],
        ),
      );
      final refreshed = await notifier.reload();
      expect(refreshed.byId(stale.id).name, 'Other app');
      await notifier.saveTemplate(
        refreshed.byId(stale.id).copyWith(name: 'After reload'),
      );
      expect(
        container.read(frameCatalogProvider).requireValue.byId(stale.id).name,
        'After reload',
      );
    },
  );

  test(
    'failed publication preserves previous metadata, immutable artwork, and state',
    () async {
      final good = FrameCatalogRepository(directory: directory, seed: seed);
      await good.save(seed);
      final old = await File('${directory.path}/catalog.json').readAsBytes();
      final image = img.Image(width: 20, height: 30, numChannels: 4);
      final png = Uint8List.fromList(img.encodePng(image));
      final art = await good.importPng(png, 'frame.png');
      final broken = FrameCatalogRepository(
        directory: directory,
        seed: seed,
        publishManifest: (_, __) async =>
            throw const FileSystemException('simulated full disk'),
      );
      final container = ProviderContainer(
        overrides: [
          frameCatalogRepositoryProvider.overrideWith((ref) async => broken),
        ],
      );
      addTearDown(container.dispose);
      await container.read(frameCatalogProvider.future);
      await expectLater(
        container
            .read(frameCatalogProvider.notifier)
            .saveTemplate(
              FrameTemplate.create(
                kind: FrameTemplateKind.classicPortrait,
                name: 'New',
                artwork: art,
              ),
            ),
        throwsA(isA<FrameCatalogException>()),
      );
      expect(await File('${directory.path}/catalog.json').readAsBytes(), old);
      expect(await good.loadArtwork(art), png);
      expect(
        container.read(frameCatalogProvider).requireValue.templates,
        hasLength(4),
      );
      expect(
        () => FrameArtworkLoader.ownedFile('../escape.png', directory),
        throwsA(isA<FrameCatalogException>()),
      );
      await expectLater(
        good.importPng(Uint8List(40), 'bad.png'),
        throwsA(isA<FrameCatalogException>()),
      );
    },
  );

  test(
    'last usable product and compatible frame changes reject without poisoning the write queue',
    () async {
      final repository = FrameCatalogRepository(
        directory: directory,
        seed: seed,
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
      final notifier = container.read(frameCatalogProvider.notifier);
      await notifier.setProductEnabled(KioskProduct.classic, false);
      await notifier.setProductEnabled(KioskProduct.flipbook, false);
      await expectLater(
        notifier.setProductEnabled(KioskProduct.keychain, false),
        throwsA(isA<FrameCatalogException>()),
      );
      await expectLater(
        notifier.setFrameEnabled(FrameTemplateKind.classicPortrait.name, false),
        throwsA(isA<FrameCatalogException>()),
      );
      final current = container.read(frameCatalogProvider).requireValue;
      expect(current.isProductUsable(KioskProduct.keychain), isTrue);
      expect(
        current.byId(FrameTemplateKind.classicPortrait.name).enabled,
        isTrue,
      );
      await notifier.saveTemplate(
        current
            .byId(FrameTemplateKind.classicPortrait.name)
            .copyWith(name: 'Still writable'),
      );
      expect(
        container
            .read(frameCatalogProvider)
            .requireValue
            .byId(FrameTemplateKind.classicPortrait.name)
            .name,
        'Still writable',
      );
    },
  );

  test(
    'unavailable local storage preserves staff access with bundled fallback',
    () async {
      final blocked = File('${directory.path}/blocked');
      await blocked.writeAsString('a file occupies the directory path');
      final repository = FrameCatalogRepository(
        directory: Directory(blocked.path),
        seed: seed,
      );
      final container = ProviderContainer(
        overrides: [
          frameCatalogRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final loaded = await container.read(frameCatalogProvider.future);
      expect(loaded.warning, contains('storage is unavailable'));
      expect(loaded.isProductUsable(KioskProduct.classic), isTrue);
      expect(FrameCatalogRuntime.instance.redirect('/settings'), isNull);
      expect(
        await blocked.readAsString(),
        'a file occupies the directory path',
      );
    },
  );

  test(
    'corrupt primary recovers backup and preserves original on next save',
    () async {
      final repository = FrameCatalogRepository(
        directory: directory,
        seed: seed,
      );
      await repository.save(seed);
      await repository.save(
        seed.copyWith(enabledProducts: {KioskProduct.keychain}),
      );
      await File('${directory.path}/catalog.json').writeAsString('{broken');
      final recoveredRepository = FrameCatalogRepository(
        directory: directory,
        seed: seed,
      );
      final recovered = await recoveredRepository.load();
      expect(recovered.warning, contains('recovered'));
      expect(recovered.enabledProducts, KioskProduct.values.toSet());
      await recoveredRepository.save(recovered);
      final originals = await directory
          .list()
          .where((f) => f.path.contains('catalog-recovered-'))
          .cast<File>()
          .toList();
      expect(originals, hasLength(1));
      expect(await originals.single.readAsString(), '{broken');
    },
  );

  test('future schema is preserved and editing blocked', () async {
    final original = jsonEncode({
      'schemaVersion': 99,
      'unknown': 'must survive',
    });
    await File('${directory.path}/catalog.json').writeAsString(original);
    final repository = FrameCatalogRepository(directory: directory, seed: seed);
    final loaded = await repository.load();
    expect(loaded.warning, contains('newer'));
    await expectLater(
      repository.save(seed),
      throwsA(isA<FrameCatalogException>()),
    );
    expect(
      await File('${directory.path}/catalog.json').readAsString(),
      original,
    );
  });

  test(
    'a second app writer cannot overwrite choices saved since its load',
    () async {
      final first = FrameCatalogRepository(directory: directory, seed: seed);
      final second = FrameCatalogRepository(directory: directory, seed: seed);
      await first.load();
      await second.load();
      await first.save(seed.copyWith(enabledProducts: {KioskProduct.keychain}));
      await expectLater(
        second.save(
          seed.copyWith(
            templates: [
              for (final t in seed.templates)
                t.copyWith(name: 'Stale second app'),
            ],
          ),
        ),
        throwsA(
          isA<FrameCatalogException>().having(
            (e) => e.message,
            'message',
            contains('Another application instance changed'),
          ),
        ),
      );
      final latest = await second.load();
      expect(latest.enabledProducts, {KioskProduct.keychain});
      await second.save(
        latest.copyWith(
          templates: [
            for (final t in latest.templates)
              t.copyWith(name: 'Reloaded second app'),
          ],
        ),
      );
      expect((await first.load()).enabledProducts, {KioskProduct.keychain});
    },
  );

  test(
    'an active OS writer lock rejects a competing save without changes',
    () async {
      final repository = FrameCatalogRepository(
        directory: directory,
        seed: seed,
      );
      await repository.load();
      final lock = await File(
        '${directory.path}/catalog.lock',
      ).open(mode: FileMode.append);
      await lock.lock(FileLock.exclusive);
      try {
        await expectLater(
          repository.save(seed),
          throwsA(isA<FrameCatalogException>()),
        );
        expect(await File('${directory.path}/catalog.json').exists(), isFalse);
      } finally {
        await lock.unlock();
        await lock.close();
      }
      await repository.save(seed);
      expect(await File('${directory.path}/catalog.json').exists(), isTrue);
    },
  );

  test(
    'disabled routes block new sessions but accepted session keeps revision',
    () {
      final runtime = FrameCatalogRuntime.instance;
      runtime.replaceCatalog(seed);
      runtime.beginSession(KioskMode.classicLandscape);
      final pinned = FrameConstants.availableFrames.firstWhere(
        (f) => f.id == FrameTemplateKind.classicLandscape.name,
      );
      runtime.replaceCatalog(
        seed.copyWith(
          enabledProducts: {KioskProduct.keychain},
          templates: [
            for (final t in seed.templates)
              t.copyWith(name: 'Changed', revision: 2),
          ],
        ),
      );
      expect(runtime.redirect('/classic/start'), '/');
      expect(runtime.redirect('/classic/organize'), isNull);
      expect(runtime.redirect('/settings'), isNull);
      expect(runtime.redirect('/flipbook/capture'), '/');
      expect(
        FrameConstants.availableFrames
            .firstWhere((f) => f.id == pinned.id)
            .name,
        pinned.name,
      );
      expect(
        () => runtime.beginSession(KioskMode.classicLandscape),
        throwsA(isA<FrameCatalogException>()),
      );
      runtime.endSession();
      expect(runtime.redirect('/classic/organize'), '/');
      expect(runtime.redirect('/keychain/design'), '/keychain/start');
    },
  );
}
