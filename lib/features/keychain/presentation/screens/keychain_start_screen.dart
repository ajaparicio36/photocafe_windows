import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/confirm_discard_session.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/keychain/domain/data/providers/keychain_session_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class KeychainStartScreen extends ConsumerWidget {
  const KeychainStartScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    if ((ref.read(photoProvider).value?.photos.isNotEmpty ?? false) ||
        ref.read(bouncySessionProvider).hasWork) {
      if (!await confirmDiscardSession(context) || !context.mounted) return;
    }

    try {
      FrameCatalogRuntime.instance.beginSession(KioskMode.keychain);
      await ref.read(photoProvider.notifier).clearAllPhotos();
      await ref.read(photoProvider.notifier).setCaptureCount(4);
      await ref.read(printerProvider.notifier).setLayoutMode(4);
      await ref.read(printerProvider.notifier).setLandscapeOrientation(false);
      ref.read(keychainSessionProvider.notifier).reset();
      if (context.mounted) {
        context.go('/keychain/capture');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start Keychain session: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => EventCanvas(
    child: Stack(
      children: [
        Positioned(
          top: 56,
          left: 44,
          child: EventBackButton(onPressed: () => context.go('/')),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 46,
          child: Center(
            child: Image.asset(
              'assets/event/clickclick_logo_white.png',
              width: 155,
              height: 155,
              semanticLabel: 'Click Click',
            ),
          ),
        ),
        const Positioned(
          left: 435,
          right: 435,
          top: 225,
          child: EventPlaque(
            title: 'Keychain',
            subtitle: 'Capture and keep a memory',
          ),
        ),
        Positioned(
          left: 250,
          right: 250,
          top: 349,
          height: 260,
          child: Container(
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: EventDesign.red, width: 7),
            ),
            child: const Column(
              children: [
                Text(
                  'FOUR LITTLE MEMORIES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: EventDesign.display,
                    fontSize: 28,
                    color: EventDesign.red,
                  ),
                ),
                SizedBox(height: 28),
                Text(
                  'Capture four photos, then design four unique mini strips from the same originals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: EventDesign.body,
                    fontSize: 21,
                    height: 1.5,
                    color: EventDesign.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 278,
          top: 260,
          child: Image.asset(
            'assets/event/home_screen_figure2.png',
            width: 165,
            height: 100,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        Positioned(
          left: 455,
          right: 455,
          top: 645,
          child: EventButton(
            label: 'START KEYCHAIN',
            icon: Icons.arrow_forward_rounded,
            glossy: true,
            height: 72,
            onPressed: () => _start(context, ref),
          ),
        ),
      ],
    ),
  );
}
