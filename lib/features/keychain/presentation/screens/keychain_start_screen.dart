import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/keychain/domain/data/providers/keychain_session_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class KeychainStartScreen extends ConsumerWidget {
  const KeychainStartScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    try {
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
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF740000),
                      size: 36,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.key_rounded,
                        color: Color(0xFF740000),
                        size: 72,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'KEYCHAIN MODE',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF740000),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Capture four photos, then design four unique mini strips from the same originals.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 18,
                          color: Color(0xFF740000),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 78,
                        child: ElevatedButton.icon(
                          onPressed: () => _start(context, ref),
                          icon: const Icon(Icons.camera_alt_rounded, size: 30),
                          label: const Text(
                            'START KEYCHAIN',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF740000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
