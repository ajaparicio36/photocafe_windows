import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';

class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(frameCatalogProvider).value;
    if (FrameCatalogRuntime.instance.sessionMode != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => FrameCatalogRuntime.instance.endSession(),
      );
    }
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
                  if (catalog?.isProductUsable(KioskProduct.classic) ?? false)
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
                  if (catalog?.isProductUsable(KioskProduct.flipbook) ?? false)
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
                  if (catalog?.isProductUsable(KioskProduct.keychain) ?? false)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/keychain/start'),
                        child: Image.asset(
                          'assets/design/start/start_keychain.png',
                          fit: BoxFit.contain,
                          height: 360,
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
