import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import '../../../../core/colors/colors.dart';

class ClassicStartScreen extends ConsumerWidget {
  const ClassicStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF76220B), // Warm brown background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEE),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF76220B),
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Logo
                Container(
                  height: 120,
                  child: Image.asset(
                    'assets/icons/clickclick_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 80),

                // Classic Mode Header Button
                GestureDetector(
                  child: Container(
                    height: 120,
                    child: Image.asset(
                      'assets/icons/classic_mode_button.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 100),

                // Photo options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Photo Box option
                    _buildPhotoOption(
                      context,
                      ref,
                      assetPath: 'assets/icons/photobox_button.png',
                      layoutMode: 2,
                    ),

                    const SizedBox(width: 60),

                    // Photo Strip option
                    _buildPhotoOption(
                      context,
                      ref,
                      assetPath: 'assets/icons/strip_button.png',
                      layoutMode: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
    BuildContext context,
    WidgetRef ref, {
    required String assetPath,
    required int layoutMode,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
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
                      color: const Color(0xFFFFFBEE),
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
                            color: const Color(0xFFFFFBEE),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF76220B),
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Setting up photo session...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFFBEE),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparing ${layoutMode == 2 ? "Photo Box" : "Photo Strip"} layout',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFFFBEE).withOpacity(0.8),
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

            // Always set capture count to 4 (layout only affects arrangement)
            await photoNotifier.setCaptureCount(4);
            print('Capture count set to: 4 (always capture 4 photos)');

            // Verify the setup
            final photoState = ref.read(photoProvider).value;
            final printerState = ref.read(printerProvider).value;

            print(
              'Setup verified - Capture count: ${photoState?.captureCount}, Layout mode: ${printerState?.layoutMode}',
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Try Again',
                                style: TextStyle(
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
        },
        child: Container(
          color: AppColors.lightCard,
          padding: const EdgeInsets.symmetric(vertical: 16),
          height: 400,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
