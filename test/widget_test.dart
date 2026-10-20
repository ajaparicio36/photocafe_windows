import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-home-');
    final repository = FrameCatalogRepository(
      directory: directory,
      seed: await bundledFrameCatalog(),
    );
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
  testWidgets('start screen exposes all three experiences', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AppStartScreen()),
      ),
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
    for (final product in [
      'assets/design/home/home_classic.png',
      'assets/design/home/home_flipbook.png',
      'assets/design/start/start_keychain.png',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == product,
        ),
        findsOneWidget,
      );
    }
    await tester.runAsync(() async {
      final notifier = container.read(frameCatalogProvider.notifier);
      await notifier.setProductEnabled(KioskProduct.classic, false);
      await notifier.setProductEnabled(KioskProduct.flipbook, false);
    });
    await tester.pump();
    for (final hidden in [
      'assets/design/home/home_classic.png',
      'assets/design/home/home_flipbook.png',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == hidden,
        ),
        findsNothing,
      );
    }
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });
}
