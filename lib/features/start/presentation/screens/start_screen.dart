import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/features/classic/domain/arcade_flow.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/widgets/confirm_discard_session.dart';

class AppStartScreen extends ConsumerStatefulWidget {
  const AppStartScreen({super.key});
  @override
  ConsumerState<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends ConsumerState<AppStartScreen> {
  bool _starting = false;
  String? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_starting) FrameCatalogRuntime.instance.endSession();
    });
  }

  Future<void> _startArcade() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      if ((ref.read(photoProvider).value?.photos.isNotEmpty ?? false) ||
          ref.read(bouncySessionProvider).hasWork) {
        if (!await confirmDiscardSession(context) || !mounted) return;
      }
      await ref.read(arcadeFlowProvider).start();
      if (mounted) context.go('/classic/capture');
    } catch (error) {
      if (mounted) {
        setState(() => _startError = 'Could not start Arcade Mode: $error');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(frameCatalogProvider);
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
              (product) =>
                  state.value?.isCustomerProductUsable(product.$1) ?? false,
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
              onPressed: _starting ? null : () => context.go('/settings'),
              icon: const Icon(
                Icons.settings,
                color: EventDesign.white,
                size: 42,
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/event/clickclick_logo_white.png',
                width: 280,
                height: 280,
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
            top: 350,
            left: 30,
            right: 30,
            child: Text(
              'CLICK CLICK PHOTOBOOTH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: EventDesign.display,
                color: EventDesign.white,
                fontSize: 55,
              ),
            ),
          ),
          const Positioned(
            top: 434,
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
              data: (catalog) => _starting
                  ? const EventMessage(message: 'Preparing your photo session…')
                  : _startError != null
                  ? EventMessage(
                      message: _startError!,
                      action: EventButton(
                        label: 'RETRY',
                        onPressed: _startArcade,
                      ),
                    )
                  : catalog.arcadeEnabled && catalog.arcadeProblem != null
                  ? const EventMessage(
                      message:
                          'Arcade Mode needs a frame. Please ask staff to open Frames & modes.',
                    )
                  : Row(
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
                                    onPressed: catalog.arcadeEnabled
                                        ? _startArcade
                                        : () => context.go(products[i].$4),
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
