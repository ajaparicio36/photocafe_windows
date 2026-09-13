import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

          // Button area positioned at bottom - horizontal layout
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 120),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Classic Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/classic/start'),
                      child: Image.asset(
                        'assets/design/home/home_classic.png',
                        fit: BoxFit.contain,
                        height: 360,
                      ),
                    ),
                  ),

                  const SizedBox(width: 60),

                  // Flipbook Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/flipbook/start'),
                      child: Image.asset(
                        'assets/design/home/home_flipbook.png',
                        fit: BoxFit.contain,
                        height: 360,
                      ),
                    ),
                  ),

                  const SizedBox(width: 40),

                  // Keychain Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/keychain/start'),
                      child: Container(
                        height: 360,
                        decoration: BoxDecoration(
                          color: const Color(0xFF740000),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.key_rounded,
                              color: Colors.white,
                              size: 92,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'KEYCHAIN',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '4 mini designs',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
