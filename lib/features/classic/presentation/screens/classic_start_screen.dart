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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/design/start/start_bg.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        color: Color(0xFF740000),
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Photo options - horizontally aligned buttons
                Center(
                  child: SizedBox(
                    width: 800,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Portrait Strips button (left)
                        _buildPhotoOption(
                          context,
                          ref,
                          assetPath: 'assets/design/start/start_strips.png',
                          layoutMode: 4,
                          isLandscape: false,
                          captureCount: 4,
                        ),

                        const SizedBox(width: 40),

                        _buildPhotoOption(
                          context,
                          ref,
                          assetPath: 'assets/design/start/start_strips_3x2.png',
                          layoutMode: 3,
                          isLandscape: false,
                          captureCount: 3,
                        ),

                        // // Photo Box button (middle)
                        // _buildPhotoOption(
                        //   context,
                        //   ref,
                        //   assetPath: 'assets/design/start/start_box.png',
                        //   layoutMode: 2,
                        //   isLandscape: false,
                        //   captureCount: 4,
                        // ),
                        // const SizedBox(width: 40),

                        // Landscape Strips button (right)
                        // _buildPhotoOption(
                        //   context,
                        //   ref,
                        //   assetPath: 'assets/design/start/start_landscape.png',
                        //   layoutMode: 4,
                        //   isLandscape: true,
                        //   captureCount: 4,
                        // ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),
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
    required bool isLandscape,
    required int captureCount,
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

            await photoNotifier.setCaptureCount(captureCount);
            print('Capture count set to: $captureCount');

            // Verify the setup
            final photoState = ref.read(photoProvider).value;
            final printerState = ref.read(printerProvider).value;

            print(
              'Setup verified - Capture count: ${photoState?.captureCount}, Layout mode: ${printerState?.layoutMode}, Landscape: ${printerState?.isLandscape}',
            );

            if (photoState?.captureCount != captureCount) {
              throw Exception(
                'Capture count setup failed: expected $captureCount, got ${photoState?.captureCount}',
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
        },
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
