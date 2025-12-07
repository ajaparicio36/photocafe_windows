import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import '../../../../core/colors/colors.dart';

class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (contains everything except buttons)
          Image.asset('assets/design/home/home_bg.png', fit: BoxFit.fill),

          // Settings button overlay
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: () => context.go('/settings'),
              icon: const Icon(
                Icons.settings_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          // Button area positioned at bottom - single classic mode button
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Center(
              child: GestureDetector(
                onTap: () => _startPhotoSession(context, ref),
                child: Image.asset(
                  'assets/design/home/home_classic.png',
                  fit: BoxFit.contain,
                  height: 360,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startPhotoSession(BuildContext context, WidgetRef ref) async {
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

      // Set layout mode to 4 (portrait strips)
      await printerNotifier.setLayoutMode(4);

      // Set landscape orientation to false
      await printerNotifier.setLandscapeOrientation(false);

      // Always set capture count to 4
      await photoNotifier.setCaptureCount(4);

      // Verify the setup
      final photoState = ref.read(photoProvider).value;

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

        // Navigate directly to capture screen
        context.go('/classic/capture');
      }
    } catch (e) {
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
