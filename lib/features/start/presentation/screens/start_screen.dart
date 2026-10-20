import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/widgets/event_design.dart';

class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(frameCatalogProvider);
    if (FrameCatalogRuntime.instance.sessionMode != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => FrameCatalogRuntime.instance.endSession(),
      );
    }
    final products =
        [
              (
                KioskProduct.classic,
                'CLASSIC MODE',
                'Capture photos in strips',
                '/classic/start',
                'home_screen_figure1.png',
              ),
              (
                KioskProduct.keychain,
                'KEYCHAIN MODE',
                'Capture and keep a memory',
                '/keychain/start',
                'home_screen_figure2.png',
              ),
              (
                KioskProduct.flipbook,
                'FLIPBOOK MODE',
                'Create an animated flipbook',
                '/flipbook/start',
                'home_screen_figure3.png',
              ),
            ]
            .where(
              (product) => state.value?.isProductUsable(product.$1) ?? false,
            )
            .toList();
    return EventCanvas(
      child: Stack(
        children: [
          Positioned(
            top: 30,
            left: 32,
            child: IconButton(
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
              icon: const Icon(
                Icons.settings,
                color: EventDesign.white,
                size: 42,
              ),
            ),
          ),
          Positioned(
            top: 58,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/event/clickclick_logo_white.png',
                width: 240,
                height: 240,
                semanticLabel: 'Click Click',
              ),
            ),
          ),
          const Positioned(
            top: 320,
            left: 0,
            right: 0,
            child: Text(
              'Welcome to',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: EventDesign.body,
                color: EventDesign.white,
                fontSize: 22,
              ),
            ),
          ),
          const Positioned(
            top: 356,
            left: 30,
            right: 30,
            child: Text(
              'CLICK CLICK PHOTOBOOTH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: EventDesign.display,
                color: EventDesign.white,
                fontSize: 43,
              ),
            ),
          ),
          const Positioned(
            top: 421,
            left: 0,
            right: 0,
            child: Text(
              'CHOOSE YOUR OWN UNIQUE EXPERIENCE:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: EventDesign.body,
                color: EventDesign.white,
                fontSize: 21,
                letterSpacing: 3,
              ),
            ),
          ),
          Positioned(
            top: 476,
            left: 58,
            right: 58,
            height: 196,
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, stack) => EventMessage(
                message: 'The menu could not load.',
                action: EventButton(
                  label: 'RETRY',
                  onPressed: () => ref.invalidate(frameCatalogProvider),
                ),
              ),
              data: (_) => Row(
                children: [
                  for (var i = 0; i < products.length; i++) ...[
                    if (i > 0) const SizedBox(width: 28),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: EventButton(
                              label: products[i].$2,
                              subtitle: products[i].$3,
                              height: 103,
                              glossy: true,
                              display: true,
                              onPressed: () => context.go(products[i].$4),
                            ),
                          ),
                          Positioned(
                            left: i == 2 ? null : 25,
                            right: i == 2 ? 35 : null,
                            top: 0,
                            child: IgnorePointer(
                              child: Image.asset(
                                'assets/event/${products[i].$5}',
                                width: 145,
                                height: 108,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 42,
            left: 0,
            right: 0,
            child: Text(
              'Find your Clique, in every Click',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: EventDesign.body,
                fontStyle: FontStyle.italic,
                color: EventDesign.white,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
