import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/frame_catalog/presentation/screens/frame_catalog_screen.dart';
import 'package:photocafe_windows/features/frame_catalog/presentation/screens/frame_editor_screen.dart';
import 'package:photocafe_windows/features/frame_catalog/presentation/widgets/frame_slot_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FrameCatalog seed;
  late Uint8List png;
  late FrameCatalogRepository repository;
  late ProviderContainer container;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('frame-editor-widget-');
    png = Uint8List.fromList(
      img.encodePng(img.Image(width: 24, height: 24, numChannels: 4)),
    );
    await Directory('${directory.path}/artwork').create();
    await File('${directory.path}/artwork/seed.png').writeAsBytes(png);
    seed = FrameCatalog(
      templates: [
        for (final kind in FrameTemplateKind.values)
          FrameTemplate(
            id: kind.name,
            name: '${kind.name} frame',
            revision: 1,
            kind: kind,
            artwork: const FrameArtwork(
              path: 'artwork/seed.png',
              isBundled: false,
              pixelWidth: 24,
              pixelHeight: 24,
            ),
            slots: const [
              FrameSlot(
                id: 'slot-one',
                photoIndex: 0,
                left: 50,
                top: 70,
                width: 100,
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
    container = ProviderContainer(
      overrides: [
        frameCatalogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await container.read(frameCatalogProvider.future);
  });

  tearDown(() async {
    container.dispose();
    FrameCatalogRuntime.instance.resetForTesting();
    await directory.delete(recursive: true);
  });

  // The real repository uses file I/O, which pumpAndSettle's fake clock
  // cannot drain. Wait for actual work, then settle the widget tree.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      if (find.text('Loading frame artwork…').evaluate().isEmpty &&
          find.text('Saving…').evaluate().isEmpty &&
          find.text('Saving change…').evaluate().isEmpty) {
        return;
      }
    }
    fail('Editor I/O did not settle.');
  }

  Future<void> openCatalog(WidgetTester tester, Size size) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FrameCatalogScreen()),
      ),
    );
    await settle(tester);
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('edit-frame-classicPortrait')));
    await settle(tester);
    expect(find.byType(FrameEditorScreen), findsOneWidget);
  }

  for (final size in [const Size(1280, 720), const Size(1280, 800)]) {
    testWidgets(
      'catalog and editor fit ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await openCatalog(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('Frames & modes'), findsOneWidget);
        await openEditor(tester);
        expect(tester.takeException(), isNull);
        final canvas = tester.getRect(
          find.byKey(const ValueKey('frame-slot-canvas')),
        );
        final save = tester.getRect(find.byKey(const ValueKey('save-frame')));
        expect(canvas.left, greaterThanOrEqualTo(0));
        expect(canvas.bottom, lessThanOrEqualTo(size.height));
        expect(save.right, lessThanOrEqualTo(size.width));
        expect(save.bottom, lessThanOrEqualTo(size.height));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('numeric slot edits and source-photo changes persist on Save', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const ValueKey('frame-name')),
      'Event red',
    );
    await tester.enterText(find.byKey(const ValueKey('slot-left')), '-12.5');
    await tester.enterText(find.byKey(const ValueKey('slot-width')), '125.25');
    await tester.enterText(find.byKey(const ValueKey('slot-rotation')), '37');
    await tester.tap(find.byKey(const ValueKey('photo-index-slot-one')));
    await settle(tester);
    await tester.tap(find.text('Photo 4').last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(find.byType(FrameEditorScreen), findsNothing);
    final saved = await tester.runAsync(repository.load);
    final frame = saved!.byId('classicPortrait');
    expect(frame.name, 'Event red');
    expect(frame.revision, 2);
    expect(frame.slots.single.left, -12.5);
    expect(frame.slots.single.width, 125.25);
    expect(frame.slots.single.rotationDegrees, 37);
    expect(frame.slots.single.photoIndex, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cancel keeps the saved layout and asks before discarding', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.enterText(find.byKey(const ValueKey('slot-left')), '99');
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await settle(tester);
    expect(find.byType(FrameEditorScreen), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    await tester.tap(find.text('Discard changes'));
    await settle(tester);
    expect(find.byType(FrameEditorScreen), findsNothing);
    expect(
      container
          .read(frameCatalogProvider)
          .requireValue
          .byId('classicPortrait')
          .slots
          .single
          .left,
      50,
    );
    expect(
      await tester.runAsync(
        () => File('${directory.path}/catalog.json').exists(),
      ),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invalid numeric input blocks Save without losing the draft', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.enterText(find.byKey(const ValueKey('slot-width')), '-1');
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(find.text('Must be above zero.'), findsOneWidget);
    expect(find.byType(FrameEditorScreen), findsOneWidget);
    expect(
      await tester.runAsync(
        () => File('${directory.path}/catalog.json').exists(),
      ),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stale Save leaves the local draft and offers reload', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const ValueKey('frame-name')),
      'My draft',
    );
    await tester.runAsync(
      () => container
          .read(frameCatalogProvider.notifier)
          .saveTemplate(
            seed.byId('classicPortrait').copyWith(name: 'Another saved edit'),
          ),
    );
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(
      find.textContaining('changed while you were editing'),
      findsOneWidget,
    );
    expect(find.text('My draft'), findsOneWidget);
    expect(find.text('Reload saved version'), findsOneWidget);
    expect(
      container
          .read(frameCatalogProvider)
          .requireValue
          .byId('classicPortrait')
          .name,
      'Another saved edit',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('save I/O failure is visible and keeps editable local values', (
    tester,
  ) async {
    container.dispose();
    repository = FrameCatalogRepository(
      directory: directory,
      seed: seed,
      publishManifest: (source, destination) async {
        throw const FileSystemException('Simulated storage failure');
      },
    );
    container = ProviderContainer(
      overrides: [
        frameCatalogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.runAsync(() => container.read(frameCatalogProvider.future));
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.enterText(find.byKey(const ValueKey('slot-top')), '134.5');
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(find.textContaining('Frames were not saved.'), findsOneWidget);
    expect(find.text('134.5'), findsOneWidget);
    expect(
      container
          .read(frameCatalogProvider)
          .requireValue
          .byId('classicPortrait')
          .slots
          .single
          .top,
      70,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-frame')))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('product switches reject disabling the final usable mode', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await tester.tap(find.byKey(const ValueKey('product-classic')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('product-keychain')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('product-flipbook')));
    await settle(tester);
    expect(
      find.text('Keep at least one usable product enabled.'),
      findsOneWidget,
    );
    expect(container.read(frameCatalogProvider).requireValue.enabledProducts, {
      KioskProduct.flipbook,
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('new draft recovers from an external save without losing slots', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    final artwork = await tester.runAsync(
      () => container
          .read(frameCatalogProvider.notifier)
          .importPng(png, 'new-frame.png'),
    );
    final draft = FrameTemplate.create(
      kind: FrameTemplateKind.classicPortrait,
      name: 'New event frame',
      artwork: artwork!,
    );
    final context = tester.element(find.byType(FrameCatalogScreen));
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            FrameEditorScreen(template: draft, isNew: true, artworkBytes: png),
      ),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('slot-left')), '43.5');
    await tester.enterText(find.byKey(const ValueKey('slot-rotation')), '18');
    await tester.runAsync(() async {
      final competing = FrameCatalogRepository(
        directory: directory,
        seed: seed,
      );
      final latest = await competing.load();
      await competing.save(
        latest.copyWith(
          enabledProducts: {KioskProduct.classic, KioskProduct.keychain},
        ),
      );
    });
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(
      find.textContaining('Another application instance changed'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reload catalog and keep draft'));
    await settle(tester);
    expect(find.text('43.5'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('New event frame'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    expect(find.byType(FrameEditorScreen), findsNothing);
    final saved = container.read(frameCatalogProvider).requireValue;
    expect(saved.byId(draft.id).slots.single.left, 43.5);
    expect(saved.byId(draft.id).slots.single.rotationDegrees, 18);
    expect(saved.byId(draft.id).enabled, isFalse);
    expect(saved.enabledProducts, {
      KioskProduct.classic,
      KioskProduct.keychain,
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('frame toggle shows domain rejection and stays enabled', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await tester.tap(
      find.byKey(const ValueKey('enable-frame-classicPortrait')),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('catalog-error')), findsOneWidget);
    expect(
      container
          .read(frameCatalogProvider)
          .requireValue
          .byId('classicPortrait')
          .enabled,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('adding and duplicating slots retains unique IDs', (
    tester,
  ) async {
    await openCatalog(tester, const Size(1280, 800));
    await openEditor(tester);
    await tester.tap(find.byKey(const ValueKey('add-slot')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('duplicate-slot')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-frame')));
    await settle(tester);
    final frame = container
        .read(frameCatalogProvider)
        .requireValue
        .byId('classicPortrait');
    expect(frame.slots, hasLength(3));
    expect(frame.slots.map((slot) => slot.id).toSet(), hasLength(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('canvas move, resize, rotate and keyboard use renderer points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var draft = seed.byId('classicPortrait');
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: FrameSlotCanvas(
              template: draft,
              artwork: png,
              selectedSlotId: 'slot-one',
              onSelect: (_) {},
              onSlotChanged: (slot) {
                setState(() => draft = draft.copyWith(slots: [slot]));
              },
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    final scale = math.min((800 - 88) / 297.6, (600 - 88) / 442.56);
    final origin = Offset((800 - 297.6 * scale) / 2, 44);
    Offset screen(Offset point) => origin + point * scale;
    var slot = draft.slots.single;
    final center = Offset(
      slot.left + slot.width / 2,
      slot.top + slot.height / 2,
    );
    await tester.dragFrom(screen(center), Offset(20 * scale, 15 * scale));
    await tester.pump();
    expect(draft.slots.single.left, closeTo(70, 0.01));
    expect(draft.slots.single.top, closeTo(85, 0.01));
    slot = draft.slots.single;
    await tester.dragFrom(
      screen(Offset(slot.left + slot.width, slot.top + slot.height)),
      Offset(25 * scale, 10 * scale),
    );
    await tester.pump();
    expect(draft.slots.single.width, closeTo(125, 0.01));
    expect(draft.slots.single.height, closeTo(90, 0.01));
    slot = draft.slots.single;
    final rotationCenter = screen(
      Offset(slot.left + slot.width / 2, slot.top + slot.height / 2),
    );
    final radius = slot.height * scale / 2 + 30;
    final gesture = await tester.startGesture(
      rotationCenter + Offset(0, -radius),
    );
    await gesture.moveTo(rotationCenter + Offset(radius, 0));
    await gesture.up();
    await tester.pump();
    expect(draft.slots.single.rotationDegrees, closeTo(90, 0.01));
    final oldLeft = draft.slots.single.left;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(draft.slots.single.left, closeTo(oldLeft + 1, 0.01));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(draft.slots.single.left, closeTo(oldLeft + 11, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
