import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                onTap: () => context.go('/classic/start'),
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
}
