import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/colors/colors.dart';

class FlipbookStartScreen extends ConsumerWidget {
  const FlipbookStartScreen({super.key});

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

                // Flipbook Mode Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEE),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'FLIPBOOK MODE',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF76220B),
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 100),

                // Start Flipbook button
                Expanded(
                  child: Center(
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
                                          color: const Color(0xFF76220B),
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFFFBEE),
                                            strokeWidth: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Setting up flipbook...',
                                        style: TextStyle(
                                          fontFamily: 'LeagueSpartan',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF76220B),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Preparing camera for video recording',
                                        style: TextStyle(
                                          fontFamily: 'LeagueSpartan',
                                          fontSize: 14,
                                          color: const Color(
                                            0xFF76220B,
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

                          // Small delay for visual feedback
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );

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
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
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
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                      child: Container(
                        width: 400,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEE),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_camera_front,
                              size: 80,
                              color: const Color(0xFF76220B),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'START FLIPBOOK',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF76220B),
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Record a 7-second video that will be turned into a beautiful flipbook',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(
                                    0xFF76220B,
                                  ).withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
