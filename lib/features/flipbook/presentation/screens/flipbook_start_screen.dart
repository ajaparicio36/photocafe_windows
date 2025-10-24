import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookStartScreen extends ConsumerWidget {
  const FlipbookStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image with title
          Positioned.fill(
            child: Image.asset(
              'assets/design/flipbook-home/flipbook-home_bg.png',
              fit: BoxFit.fill,
            ),
          ),

          // Content overlay
          SafeArea(
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

                  // Instructions box with text overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Instructions box image
                      Image.asset(
                        'assets/design/flipbook-home/flipbook-home_instructions.png',
                        width: screenSize.width * 0.5,
                        fit: BoxFit.contain,
                      ),

                      // Instructions text overlay
                      Positioned.fill(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 40,
                            ),
                            child: Text(
                              'Click the capture button, pose for 7 seconds, then choose to proceed or retake',
                              style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF740000),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Start Clicking button
                  GestureDetector(
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
                                        color: const Color(
                                          0xFF740000,
                                        ).withOpacity(0.8),
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
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
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
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                Colors.red.shade700,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                    },
                    child: Image.asset(
                      'assets/design/clicking.png',
                      width: screenSize.width * 0.15,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
