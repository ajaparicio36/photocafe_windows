import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:image/image.dart' as img;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_print_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final body = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    final display = FontLoader('RubikMonoOne')
      ..addFont(rootBundle.load('assets/fonts/RubikMonoOne-Regular.ttf'));
    await body.load();
    await display.load();
  });

  for (final fail in [false, true]) {
    testWidgets(
      'Classic shows ${fail ? 'printer error' : 'success'} feedback',
      (tester) async {
        final printer = _FakePrinter();
        await _mount(tester, printer);
        tester
            .widget<PrintActionPanel>(find.byType(PrintActionPanel))
            .onPrint(2);
        await tester.pump();
        expect(printer._copies, 2);
        expect(printer._cut, isTrue);
        if (fail) {
          printer._completion.completeError(Exception('Printer offline'));
        } else {
          printer._completion.complete();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        if (fail) {
          expect(
            find.text('Print failed: Exception: Printer offline'),
            findsOneWidget,
          );
          expect(find.text('Print Complete!'), findsNothing);
        } else {
          expect(
            find.text('Document sent to printer successfully!'),
            findsOneWidget,
          );
          expect(find.text('Print Complete!'), findsOneWidget);
        }
        expect(
          tester
              .widget<PrintActionPanel>(find.byType(PrintActionPanel))
              .isPrinting,
          isFalse,
        );
      },
    );

    testWidgets(
      'Classic can leave while ${fail ? 'failed' : 'successful'} print is pending',
      (tester) async {
        final printer = _FakePrinter();
        await _mount(tester, printer);
        await tester.tap(find.text('PRINT PHOTOS'));
        await tester.pump();
        expect(find.text('PRINTING…'), findsOneWidget);
        await tester.tap(find.byTooltip('Back'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Photo organization'), findsOneWidget);
        expect(find.byType(ClassicPrintScreen), findsNothing);
        if (fail) {
          printer._completion.completeError(Exception('Printer offline'));
        } else {
          printer._completion.complete();
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }
}

Future<void> _mount(WidgetTester tester, _FakePrinter printer) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('net.nfet.printing'), (
        call,
      ) async {
        if (call.method == 'printingInfo') {
          return <String, bool>{'canRaster': false};
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('net.nfet.printing'),
          null,
        ),
  );
  final router = GoRouter(
    initialLocation: '/classic/print',
    routes: [
      GoRoute(
        path: '/classic/print',
        builder: (_, _) =>
            ClassicPrintScreen(pdfBytes: Uint8List.fromList([1, 2, 3])),
      ),
      GoRoute(
        path: '/classic/organize',
        builder: (_, _) => const Scaffold(body: Text('Photo organization')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        printerProvider.overrideWith(() => printer),
        photoProvider.overrideWith(_FakePhotos.new),
        bouncySessionProvider.overrideWith((ref) => _validSession()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

class _FakePrinter extends PrinterNotifier {
  final _completion = Completer<void>();
  int? _copies;
  bool? _cut;

  @override
  Future<PrinterState> build() async => const PrinterState();

  @override
  Future<void> printPdfBytes(
    Uint8List pdfBytes, {
    bool cut = false,
    int copies = 1,
  }) {
    _cut = cut;
    _copies = copies;
    return _completion.future;
  }
}

class _FakePhotos extends PhotoNotifier {
  @override
  Future<PhotoState> build() async => PhotoState(
    photos: [
      for (var i = 0; i < 4; i++)
        PhotoModel(imagePath: '', index: i, captureId: 'shot$i'),
    ],
    tempPath: '',
    captureCount: 4,
  );

  @override
  Future<String> saveFramePdf(Uint8List pdfBytes) async => 'test-frame.pdf';
}

BouncySession _validSession() {
  final session = BouncySession();
  final jpeg = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 32, height: 18)),
  );
  final clip = validateBouncyImages(
    BouncyClip([
      for (var i = 0; i <= 30; i++) BouncyFrame(i * 100000, jpeg),
    ], 3000000),
  );
  for (var i = 0; i < 4; i++) {
    session.accept(session.attempt('shot$i'), clip);
  }
  return session;
}
