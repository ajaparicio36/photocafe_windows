import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';

void main() {
  testWidgets('start screen exposes all three experiences', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppStartScreen())),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/design/start/start_keychain.png',
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsAtLeastNWidgets(3));
  });
}
