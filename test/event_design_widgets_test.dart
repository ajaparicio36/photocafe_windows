import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_filter_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_organize_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_print_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_start_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_filter_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_frame_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_print_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_start_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_takes_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/take_preview_widget.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/keychain/domain/data/providers/keychain_session_notifier.dart';
import 'package:photocafe_windows/features/keychain/presentation/screens/keychain_design_screen.dart';
import 'package:photocafe_windows/features/keychain/presentation/screens/keychain_print_screen.dart';
import 'package:photocafe_windows/features/keychain/presentation/screens/keychain_start_screen.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/settings/domain/data/providers/flipbook_archive_notifier.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/video_state.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/event_pdf_preview.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Photos extends PhotoNotifier {
  _Photos(this._initial);
  final PhotoState _initial;
  @override
  Future<PhotoState> build() async => _initial;
}

class _Videos extends VideoNotifier {
  _Videos(this._initial);
  final VideoState _initial;
  @override
  Future<VideoState> build() async => _initial;
}

class _Printer extends PrinterNotifier {
  int _calls = 0;
  @override
  Future<PrinterState> build() async => const PrinterState(layoutMode: 4);
  @override
  Future<void> printPdfBytesForVideo(Uint8List bytes) async {
    _calls++;
  }
}

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}

// The native rasterizer is outside widget tests. Keep the full-page aspect and
// record requested pages; PDF generation/archive and route bytes stay real.
class _Rasterizer extends PrintingPlatform {
  final List<int> requestedPages = [];
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    requestedPages.addAll(pages ?? [0]);
    yield PdfRaster(60, 40, Uint8List.fromList(List.filled(60 * 40 * 4, 255)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late _Printer printer;
  late _Rasterizer rasterizer;
  late PrintingPlatform oldPrinting;
  late PathProviderPlatform oldPaths;

  setUpAll(() async {
    final body = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    final display = FontLoader('RubikMonoOne')
      ..addFont(rootBundle.load('assets/fonts/RubikMonoOne-Regular.ttf'));
    await body.load();
    await display.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('event-layout-');
    final photo = File('${directory.path}/source.png');
    await photo.writeAsBytes(img.encodePng(img.Image(width: 96, height: 54)));
    oldPrinting = PrintingPlatform.instance;
    oldPaths = PathProviderPlatform.instance;
    rasterizer = _Rasterizer();
    PrintingPlatform.instance = rasterizer;
    PathProviderPlatform.instance = _Paths(directory.path);
    final repository = FrameCatalogRepository(
      directory: Directory('${directory.path}/catalog'),
      seed: await bundledFrameCatalog(),
    );
    printer = _Printer();
    container = ProviderContainer(
      overrides: [
        frameCatalogRepositoryProvider.overrideWith((ref) async => repository),
        photoProvider.overrideWith(
          () => _Photos(
            PhotoState(
              photos: [
                for (var i = 0; i < 4; i++)
                  PhotoModel(
                    imagePath: photo.path,
                    originalPath: photo.path,
                    index: i,
                    captureId: 'shot-$i',
                  ),
              ],
              tempPath: directory.path,
              captureCount: 4,
            ),
          ),
        ),
        videoProvider.overrideWith(
          () => _Videos(
            VideoState(
              videoPath: '${directory.path}/take-0.avi',
              videoTakes: [
                for (var i = 0; i < 4; i++) '${directory.path}/take-$i.avi',
              ],
              frames: [FrameModel(path: photo.path, index: 0)],
              tempPath: directory.path,
            ),
          ),
        ),
        printerProvider.overrideWith(() => printer),
      ],
    );
    await container.read(frameCatalogProvider.future);
    await container.read(photoProvider.future);
    await container.read(videoProvider.future);
    await container.read(printerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    FrameCatalogRuntime.instance.resetForTesting();
    PrintingPlatform.instance = oldPrinting;
    PathProviderPlatform.instance = oldPaths;
    await directory.delete(recursive: true);
  });

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
  }

  Future<GoRouter> open(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(
          path: '/flipbook/print',
          builder: (_, state) =>
              FlipbookPrintScreen(pdfBytes: state.extra as Uint8List?),
        ),
        GoRoute(
          path: '/flipbook/filter',
          builder: (_, _) =>
              const Scaffold(body: Text('Selected take filters')),
        ),
        GoRoute(
          path: '/flipbook/start',
          builder: (_, _) => const FlipbookStartScreen(),
        ),
        GoRoute(
          path: '/classic/organize',
          builder: (_, _) => const ClassicOrganizeScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await drain(tester);
    return router;
  }

  for (final size in [const Size(1280, 800), const Size(1024, 640)]) {
    testWidgets(
      'customer compositions fit ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final screens = <Widget>[
          const AppStartScreen(),
          const ClassicStartScreen(),
          const ClassicFilterScreen(),
          const ClassicOrganizeScreen(),
          const ClassicPrintScreen(),
          const FlipbookStartScreen(),
          const FlipbookTakesScreen(),
          const FlipbookFilterScreen(),
          const FlipbookFrameScreen(),
          const FlipbookPrintScreen(),
          const KeychainStartScreen(),
          const KeychainDesignScreen(),
          const KeychainPrintScreen(),
        ];
        for (final screen in screens) {
          await open(tester, screen, size);
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}',
          );
          for (final element in find.byType(EventPanel).evaluate()) {
            final rect = tester.getRect(find.byWidget(element.widget));
            expect(
              rect.left,
              greaterThanOrEqualTo(-1),
              reason: '${screen.runtimeType}',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(size.width + 1),
              reason: '${screen.runtimeType}',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height + 1),
              reason: '${screen.runtimeType}',
            );
          }
          expect(
            find.byType(SingleChildScrollView),
            findsNothing,
            reason: '${screen.runtimeType} should fit without page scrolling',
          );
        }
      },
    );
  }

  testWidgets('Classic menu respects remembered variant visibility', (
    tester,
  ) async {
    await tester.runAsync(
      () => container
          .read(frameCatalogProvider.notifier)
          .setClassicVariantEnabled(ClassicVariant.photobox, false),
    );
    await open(tester, const ClassicStartScreen(), const Size(1280, 800));
    expect(find.text('PHOTO\nBOX'), findsNothing);
    expect(find.text('PORTRAIT\nPHOTO\nSTRIPS'), findsOneWidget);
    expect(find.text('LANDSCAPE\nPHOTO\nSTRIP'), findsOneWidget);
    expect(find.text('START CLICKING'), findsNWidgets(2));
  });

  testWidgets('take selection enables proceed and retains selected video', (
    tester,
  ) async {
    final router = await open(
      tester,
      const FlipbookTakesScreen(),
      const Size(1280, 800),
    );
    expect(
      tester
          .widget<EventButton>(find.widgetWithText(EventButton, 'PROCEED'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(TakePreviewWidget).at(2));
    await drain(tester);
    expect(container.read(videoProvider).requireValue.selectedTakeIndex, 2);
    await tester.tap(find.text('PROCEED'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/flipbook/filter');
    expect(
      container.read(videoProvider).requireValue.videoPath,
      endsWith('take-2.avi'),
    );
  });

  testWidgets('Keychain frame choices persist independently across designs', (
    tester,
  ) async {
    await open(tester, const KeychainDesignScreen(), const Size(1280, 800));
    final choices = find.byType(EventChoice);
    final secondFrame = tester.widget<EventChoice>(choices.at(1)).title;
    await tester.tap(choices.at(1));
    await drain(tester);
    final firstChoice = container
        .read(keychainSessionProvider)
        .variants
        .first
        .frameId;
    await tester.tap(find.text('NEXT DESIGN'));
    await drain(tester);
    expect(container.read(keychainSessionProvider).designIndex, 1);
    expect(
      container.read(keychainSessionProvider).variants.first.frameId,
      firstChoice,
    );
    await tester.tap(find.text('PREVIOUS'));
    await drain(tester);
    expect(
      tester
          .widget<EventChoice>(find.widgetWithText(EventChoice, secondFrame))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Flipbook proceed archives exact PDF and opens review without printing',
    (tester) async {
      final router = await open(
        tester,
        const FlipbookFrameScreen(),
        const Size(1280, 800),
      );
      await tester.tap(find.text('PROCEED TO PRINT'));
      for (
        var i = 0;
        i < 30 &&
            router.routeInformationProvider.value.uri.path != '/flipbook/print';
        i++
      ) {
        await drain(tester);
      }
      expect(router.routeInformationProvider.value.uri.path, '/flipbook/print');
      expect(printer._calls, 0);
      await drain(tester);
      final preview = tester.widget<EventPdfPreview>(
        find.byType(EventPdfPreview),
      );
      final archives = await tester.runAsync(
        () => container.read(flipbookArchiveProvider.future),
      );
      expect(archives, hasLength(1));
      final archived = await tester.runAsync(
        () => File(archives!.single.filePath).readAsBytes(),
      );
      expect(preview.bytes, orderedEquals(archived!));
      await tester.tap(find.byTooltip('Next print page'));
      await drain(tester);
      expect(find.text('Page 2 of 25'), findsOneWidget);
      expect(rasterizer.requestedPages, contains(1));
      expect(printer._calls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
