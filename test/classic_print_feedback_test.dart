import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:image/image.dart' as img;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_print_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        expect(printer.copies, 2);
        expect(printer.cut, isTrue);
        if (fail) {
          printer.completion.completeError(Exception('Printer offline'));
        } else {
          printer.completion.complete();
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
        tester
            .widget<PrintActionPanel>(find.byType(PrintActionPanel))
            .onPrint(1);
        await tester.pump();
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        if (fail) {
          printer.completion.completeError(Exception('Printer offline'));
        } else {
          printer.completion.complete();
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        printerProvider.overrideWith(() => printer),
        photoProvider.overrideWith(_FakePhotos.new),
        bouncySessionProvider.overrideWith((ref) => _validSession()),
      ],
      child: MaterialApp(
        home: ClassicPrintScreen(pdfBytes: Uint8List.fromList([1, 2, 3])),
      ),
    ),
  );
  await tester.pump();
}

class _FakePrinter extends PrinterNotifier {
  final completion = Completer<void>();
  int? copies;
  bool? cut;

  @override
  Future<PrinterState> build() async => const PrinterState();

  @override
  Future<void> printPdfBytes(
    Uint8List pdfBytes, {
    bool cut = false,
    int copies = 1,
  }) {
    this.cut = cut;
    this.copies = copies;
    return completion.future;
  }
}

class _FakePhotos extends PhotoNotifier {
  @override
  Future<PhotoState> build() async =>
      PhotoState(photos: [for (var i = 0; i < 4; i++) PhotoModel(imagePath: '', index: i, captureId: 'shot$i')], tempPath: '', captureCount: 4);

  @override
  Future<String> saveFramePdf(Uint8List pdfBytes) async => 'test-frame.pdf';
}

BouncySession _validSession() {
  final session = BouncySession();
  final jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 32, height: 18)));
  final clip = validateBouncyImages(BouncyClip([for (var i = 0; i <= 30; i++) BouncyFrame(i * 100000, jpeg)], 3000000));
  for (var i = 0; i < 4; i++) { session.accept(session.attempt('shot$i'), clip); }
  return session;
}
