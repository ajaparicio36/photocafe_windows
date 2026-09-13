import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';

void main() {
  testWidgets('start screen exposes Photostrips and Keychain only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppStartScreen())),
    );
    await tester.pump();

    expect(find.text('KEYCHAIN'), findsOneWidget);
    expect(find.textContaining('FLIPBOOK'), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
  });
}
