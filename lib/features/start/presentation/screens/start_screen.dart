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
                  // Photostrips button.
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Photostrips',
                      child: GestureDetector(
                        onTap: () => context.go('/classic/start'),
                        child: Image.asset(
                          'assets/design/start/start_strips.png',
                          fit: BoxFit.contain,
                          height: 360,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 60),

                  // Keychain button.
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Keychain',
                      child: GestureDetector(
                        onTap: () => context.go('/keychain/start'),
                        child: Image.asset(
                          'assets/design/start/start_keychain.png',
                          fit: BoxFit.contain,
                          height: 360,
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
