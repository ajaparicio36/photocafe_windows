import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookStartScreen extends ConsumerWidget {
  const FlipbookStartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => EventCanvas(
    background: 'assets/design/flipbook-home/flipbook-home_bg.png',
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
            label: 'Flipbook mode. Create an animated flipbook.',
            child: SizedBox.shrink(),
          ),
        ),
        Positioned(
          left: 180,
          right: 180,
          top: 300,
          height: 335,
          child: Container(
            padding: const EdgeInsets.fromLTRB(60, 26, 60, 35),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: EventDesign.red, width: 8),
              borderRadius: BorderRadius.circular(42),
            ),
            child: const Column(
              children: [
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontFamily: EventDesign.body,
                    fontWeight: FontWeight.bold,
                    color: EventDesign.red,
                    fontSize: 26,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Click the capture button, pose for 7 seconds, then choose to proceed or retake.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: EventDesign.body,
                        fontSize: 25,
                        color: EventDesign.red,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 270,
          top: 208,
          child: IgnorePointer(
            child: Image.asset(
              'assets/event/flipbook_instructions_figure1.png',
              width: 160,
              height: 110,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Positioned(
          left: 470,
          right: 470,
          top: 657,
          child: EventButton(
            label: 'START CLICKING',
            icon: Icons.arrow_forward_rounded,
            height: 64,
            glossy: true,
            onPressed: () => _start(context, ref),
          ),
        ),
        Positioned(
          left: 460,
          right: 460,
          top: 733,
          child: TextButton(
            onPressed: () async {
              FrameCatalogRuntime.instance.beginSession(KioskMode.flipbook);
              await ref.read(videoProvider.notifier).clearVideo();
              if (context.mounted) context.go('/flipbook/upload');
            },
            child: const Text(
              'Upload my own video',
              style: TextStyle(
                color: Colors.white,
                fontFamily: EventDesign.body,
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    try {
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
                      color: const Color(0xFF740000),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Setting up flipbook...',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF740000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing camera for video recording',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
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

      // Clear any existing video state to start fresh
      FrameCatalogRuntime.instance.beginSession(KioskMode.flipbook);
      await ref.read(videoProvider.notifier).clearVideo();

      // Small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to flipbook capture
        context.go('/flipbook/capture');
      }
    } catch (e) {
      print('Error setting up flipbook: $e');

      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error dialog
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
                    const Text(
                      'Setup Failed',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $e',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
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
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
