import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/widgets/confirm_discard_session.dart';

void main() {
  testWidgets('discard confirmation preserves session on Keep and requires affirmative choice', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: Builder(builder: (context) =>
      TextButton(onPressed: () async { result = await confirmDiscardSession(context); }, child: const Text('New session')))));
    await tester.tap(find.text('New session')); await tester.pumpAndSettle();
    await tester.tap(find.text('Keep session')); await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('New session')); await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel and start over').last); await tester.pumpAndSettle();
    expect(result, isTrue); expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(1266, 713), const Size(1024, 576)]) {
    testWidgets('QR and actions fit ${size.width}x${size.height} with readable colors', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: Scaffold(body:
        SoftCopiesReadyDialog(downloadUrl: 'http://127.0.0.1:3017/archive/qa-fixture-1234567890', onStartOver: () {}))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Start Over'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Soft Copies Ready!')).style?.color, const Color(0xff740000));
    });
  }
}
