import 'package:photocafe_windows/widgets/confirm_discard_session.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/widgets/event_design.dart';

class ClassicStartScreen extends ConsumerWidget {
  const ClassicStartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(frameCatalogProvider).value;
    final options = [
      (
        KioskMode.classicPortrait,
        'PORTRAIT\nPHOTO\nSTRIPS',
        'classic_mode_portrait.png',
        'Two Strips\nBest for: Group Shot',
        4,
        false,
        'home_screen_figure2.png',
      ),
      (
        KioskMode.classicPhotobox,
        'PHOTO\nBOX',
        'classic_mode_photobox.png',
        'One A5 Photo Box\nBest for: 1–3 Person',
        2,
        false,
        '',
      ),
      (
        KioskMode.classicLandscape,
        'LANDSCAPE\nPHOTO\nSTRIP',
        'classic_mode_landscape.png',
        'Two Strips\nBest for: Solo Shot',
        4,
        true,
        'classic_mode_landscape_figure1.png',
      ),
    ].where((option) => catalog?.isModeUsable(option.$1) ?? false).toList();
    return EventCanvas(
      background: 'assets/design/start/start_bg.png',
      child: Stack(
        children: [
          Positioned(
            top: 56,
            left: 44,
            child: EventBackButton(onPressed: () => context.go('/')),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Semantics(
              label: 'Classic mode. Choose your template.',
              child: SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 94,
            right: 94,
            top: 290,
            bottom: 45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 44),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 65,
                          child: options[i].$7.isEmpty
                              ? null
                              : Align(
                                  alignment: i == 0
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Image.asset(
                                    'assets/event/${options[i].$7}',
                                    width: 150,
                                    height: 86,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: EventDesign.red,
                                width: 8,
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 85,
                                  child: Center(
                                    child: Text(
                                      options[i].$2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: EventDesign.display,
                                        fontSize: 26,
                                        height: 1.02,
                                        color: EventDesign.red,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Image.asset(
                                      'assets/event/${options[i].$3}',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Text(
                                  options[i].$4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: EventDesign.body,
                                    fontSize: 16,
                                    height: 1.2,
                                    color: EventDesign.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: EventButton(
                            label: 'START CLICKING',
                            icon: Icons.arrow_forward_rounded,
                            glossy: true,
                            height: 66,
                            onPressed: () => _start(
                              context,
                              ref,
                              layoutMode: options[i].$5,
                              isLandscape: options[i].$6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref, {
    required int layoutMode,
    required bool isLandscape,
  }) async {
    if ((ref.read(photoProvider).value?.photos.isNotEmpty ?? false) ||
        ref.read(bouncySessionProvider).hasWork) {
      if (!await confirmDiscardSession(context) || !context.mounted) {
        return;
      }
    }
    try {
      FrameCatalogRuntime.instance.beginSession(
        layoutMode == 2
            ? KioskMode.classicPhotobox
            : isLandscape
            ? KioskMode.classicLandscape
            : KioskMode.classicPortrait,
      );
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF740000),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setting up photo session...',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF740000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing ${layoutMode == 2
                        ? "Photo Box"
                        : isLandscape
                        ? "Landscape Strip"
                        : "Portrait Strip"} layout',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 14,
                      color: const Color(0xFF740000).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final photoNotifier = ref.read(photoProvider.notifier);
      final printerNotifier = ref.read(printerProvider.notifier);

      // Clear photos first
      await photoNotifier.clearAllPhotos();
      print('Photos cleared');

      // Set layout mode in printer settings
      await printerNotifier.setLayoutMode(layoutMode);
      print('Layout mode set to: $layoutMode');

      // Set landscape orientation if applicable
      await printerNotifier.setLandscapeOrientation(isLandscape);
      print('Landscape orientation set to: $isLandscape');

      // Always set capture count to 4 (layout only affects arrangement)
      await photoNotifier.setCaptureCount(4);
      print('Capture count set to: 4 (always capture 4 photos)');

      // Verify the setup
      final photoState = ref.read(photoProvider).value;
      final printerState = ref.read(printerProvider).value;

      print(
        'Setup verified - Capture count: ${photoState?.captureCount}, Layout mode: ${printerState?.layoutMode}, Landscape: ${printerState?.isLandscape}',
      );

      if (photoState?.captureCount != 4) {
        throw Exception(
          'Capture count setup failed: expected 4, got ${photoState?.captureCount}',
        );
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Small delay before navigation
        await Future.delayed(const Duration(milliseconds: 200));

        // Navigate to capture screen
        context.go('/classic/capture');
      }
    } catch (e) {
      print('Error setting up photo session: $e');

      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error dialog with matching design
        showDialog(
          context: context,
          builder: (context) => Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Setup Failed',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $e',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
  }
}
