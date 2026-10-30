import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/screens/classic_capture_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_organize_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_print_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_factory.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_artwork_loader.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/services/soft_copies_service.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/models/canon_connection_state.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/services/canon_camera_service.dart';
import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/widgets/canon_live_view_preview.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late FrameCatalog catalog;
  late _Canon canon;
  late BouncySession previousSession;
  late Uint8List jpeg;
  late PrintingPlatform oldPrinting;
  late _Rasterizer rasterizer;
  late List<String> uploadedNames;
  late List<MapEntry<String, String>> uploadedFields;
  late List<List<int>> uploadedBytes;
  final runtime = FrameCatalogRuntime.instance;

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
    directory = await Directory.systemTemp.createTemp('classic-bouncy-toggle-');
    await Directory('${directory.path}/photos').create();
    final art = img.Image(width: 16, height: 16, numChannels: 4);
    await Directory('${directory.path}/artwork').create();
    await File(
      '${directory.path}/artwork/frame.png',
    ).writeAsBytes(img.encodePng(art));
    jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 64, height: 36)));
    await File('${directory.path}/source.jpg').writeAsBytes(jpeg);
    catalog = FrameCatalog(
      templates: [
        FrameTemplate(
          id: 'classic',
          name: 'Classic',
          revision: 1,
          kind: FrameTemplateKind.classicPortrait,
          artwork: const FrameArtwork(
            path: 'artwork/frame.png',
            isBundled: false,
            pixelWidth: 16,
            pixelHeight: 16,
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
      enabledProducts: {KioskProduct.classic, KioskProduct.keychain},
      enabledClassicVariants: {ClassicVariant.portrait},
      classicBouncyEnabled: false,
    );
    FrameArtworkLoader.catalogDirectory = directory;
    runtime.replaceCatalog(catalog);
    runtime.beginSession(KioskMode.classicPortrait);
    previousSession = BouncySession();
    canon = _Canon(jpeg, '${directory.path}/source.jpg')
      ..bouncySession = previousSession;
    oldPrinting = PrintingPlatform.instance;
    rasterizer = _Rasterizer();
    PrintingPlatform.instance = rasterizer;
    uploadedNames = [];
    uploadedFields = [];
    uploadedBytes = [];
    dotenv.testLoad(fileInput: 'WEB_URL=https://fixture.invalid');
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          expect(options.path, '/api/upload');
          final form = options.data as FormData;
          uploadedFields = [...form.fields];
          for (final entry in form.files) {
            uploadedNames.add(entry.value.filename!);
            uploadedBytes.add(
              await entry.value.finalize().fold<List<int>>(
                [],
                (bytes, part) => bytes..addAll(part),
              ),
            );
          }
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'archiveId': 'still-archive',
                'files': [
                  for (final name in uploadedNames) {'fileName': name},
                ],
              },
            ),
          );
        },
      ),
    );
    container = ProviderContainer(
      overrides: [
        photoProvider.overrideWith(() => _Photos('${directory.path}/photos')),
        printerProvider.overrideWith(_Printer.new),
        canonCameraServiceProvider.overrideWithValue(canon),
        bouncyMediaProvider.overrideWith(
          (ref) => throw StateError('OFF unexpectedly requested motion work'),
        ),
        softCopiesServiceProvider.overrideWith(
          (ref) => SoftCopiesService(dio: dio),
        ),
      ],
    );
    await container.read(photoProvider.future);
    await container.read(printerProvider.future);
    container.read(bouncySessionProvider).setMotionEnabled(false);
  });

  tearDown(() async {
    await container.read(bouncySessionProvider).drain();
    container.dispose();
    previousSession.dispose();
    runtime.resetForTesting();
    PrintingPlatform.instance = oldPrinting;
    await directory.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: child),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }

  Future<void> drainUi(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<Uint8List> captureStills() async {
    final session = container.read(bouncySessionProvider);
    final notifier = container.read(photoProvider.notifier);
    for (var i = 0; i < 4; i++) {
      await notifier.addPhotoFromFile(
        '${directory.path}/source.jpg',
        attempt: session.attempt('shot$i'),
      );
    }
    return FrameFactory.generatePdfForFrame(
      classicDefinition(catalog.templates.single),
      container.read(photoProvider).requireValue.photos,
      4,
      false,
    );
  }

  testWidgets(
    'OFF detaches an old feed, keeps Canon live preview and strict still capture, then unmounts',
    (tester) async {
      await mount(tester, const ClassicCaptureScreen());
      expect(canon.bouncySession, isNull);
      expect(find.byType(CanonLiveViewPreview), findsOneWidget);
      expect(
        tester
            .widget<CanonLiveViewPreview>(find.byType(CanonLiveViewPreview))
            .aspectRatio,
        16 / 9,
      );
      expect(find.text('Photo capture'), findsOneWidget);
      await tester.tap(find.text('Start capture'));
      // The capture countdown intentionally uses a real monotonic Stopwatch.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await drainUi(tester);
      expect(canon.shutters, 1);
      expect(canon.hadMotionCallback, isFalse);
      expect(container.read(photoProvider).requireValue.photos, hasLength(1));
      final session = container.read(bouncySessionProvider);
      expect(session.ring.length, 0);
      expect(session.retainedBytes, 0);
      expect(session.pairCount, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
      expect(canon.bouncySession, isNull);
    },
  );

  for (final newerOwner in [false, true]) {
    testWidgets(
      'ON capture unmount detaches only its own feed (new owner: $newerOwner)',
      (tester) async {
        runtime.replaceCatalog(catalog.copyWith(classicBouncyEnabled: true));
        runtime.beginSession(KioskMode.classicPortrait);
        await mount(tester, const ClassicCaptureScreen());
        expect(
          canon.bouncySession,
          same(container.read(bouncySessionProvider)),
        );
        if (newerOwner) canon.bouncySession = previousSession;
        await tester.pumpWidget(const SizedBox());
        expect(
          canon.bouncySession,
          newerOwner ? same(previousSession) : isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'OFF organize and print display the existing framed still PDF without a motion worker',
    (tester) async {
      final pdf = await tester.runAsync(captureStills);
      await mount(tester, const ClassicOrganizeScreen());
      await drainUi(tester);
      expect(find.byType(BouncyPreview), findsNothing);
      expect(find.byKey(const ValueKey('mirror-photos')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mirror-photos')));
      await drainUi(tester);
      expect(runtime.sessionMirrorPhotos, isTrue);
      await tester.tap(find.byKey(const ValueKey('mirror-photos')));
      await drainUi(tester);
      expect(runtime.sessionMirrorPhotos, isFalse);
      for (
        var i = 0;
        i < 8 && find.byType(PdfPreview).evaluate().isEmpty;
        i++
      ) {
        await drainUi(tester);
      }
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(rasterizer.documents, isNotEmpty);
      expect(container.exists(bouncyMediaProvider), isFalse);
      await mount(tester, ClassicPrintScreen(pdfBytes: pdf!));
      await drainUi(tester);
      expect(find.byType(BouncyPreview), findsNothing);
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(rasterizer.documents, contains(orderedEquals(pdf)));
      expect(container.exists(bouncyMediaProvider), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'OFF soft copies upload original stills, extra assets, PDF and consent without MP4 work',
    (tester) async {
      final pdf = await tester.runAsync(captureStills);
      final extra = File('${directory.path}/extra.png');
      await tester.runAsync(
        () => extra.writeAsBytes(img.encodePng(img.Image(width: 2, height: 2))),
      );
      await mount(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: PrintActionPanel(
                isPrinting: false,
                splitStrips: true,
                onSplitStripsChanged: (_) {},
                onPrint: (_) {},
                pdfBytes: pdf!,
                additionalMediaFiles: [extra],
                additionalFileNames: const ['extra.png'],
              ),
            ),
          ),
        ),
      );
      // Exercise consent through the real panel before sending to an in-memory Dio interceptor.
      await tester.tap(find.text('Allow social media posting'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Agree'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Get Soft Copies'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await drainUi(tester);
      expect(find.byType(SoftCopiesReadyDialog), findsOneWidget);
      expect(uploadedNames.where((name) => name.endsWith('.mp4')), isEmpty);
      expect(
        uploadedNames,
        containsAll([
          'photo_1.jpg',
          'photo_2.jpg',
          'photo_3.jpg',
          'photo_4.jpg',
          'extra.png',
          'photostrip.png',
          'social_media_consent_agreement.txt',
        ]),
      );
      expect(uploadedBytes.take(4), everyElement(orderedEquals(jpeg)));
      expect(
        Map.fromEntries(uploadedFields)['allowSocialMediaPosting'],
        'true',
      );
      expect(container.exists(bouncyMediaProvider), isFalse);
      expect(find.textContaining('Bouncy Preview'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Photos extends PhotoNotifier {
  final String _directory;
  _Photos(this._directory);
  @override
  Future<PhotoState> build() async =>
      PhotoState(photos: [], tempPath: _directory, captureCount: 4);
}

class _Printer extends PrinterNotifier {
  @override
  Future<PrinterState> build() async => const PrinterState(layoutMode: 4);
}

class _Canon implements CanonCameraService {
  final Uint8List jpeg;
  final String source;
  int shutters = 0;
  bool? hadMotionCallback;
  _Canon(this.jpeg, this.source);
  @override
  BouncySession? bouncySession;
  @override
  bool get isInitialized => true;
  @override
  Stream<Uint8List> get liveViewStream => Stream.value(jpeg);
  @override
  Stream<CanonConnectionState> get connectionState =>
      Stream.value(CanonConnectionState.connected);
  @override
  Future<String> takeBouncyPicture({void Function()? onShutterCommand}) async {
    shutters++;
    hadMotionCallback = onShutterCommand != null;
    onShutterCommand?.call();
    return source;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Rasterizer extends PrintingPlatform {
  final List<Uint8List> documents = [];
  @override
  Future<PrintingInfo> info() async => const PrintingInfo(canRaster: true);
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    documents.add(document);
    yield PdfRaster(
      124,
      184,
      Uint8List.fromList(List.filled(124 * 184 * 4, 255)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
