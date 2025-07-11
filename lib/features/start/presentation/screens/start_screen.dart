import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to the PhotoCafe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Classic Mode', style: TextStyle(fontSize: 18)),
          ElevatedButton(
            onPressed: () {
              context.go('/classic/start');
            },
            child: const Text('Start Classic Mode'),
          ),
          const SizedBox(height: 20),
          const Text('Flipbook Mode', style: TextStyle(fontSize: 18)),
          ElevatedButton(
            onPressed: () {
              context.go('/flipbook/start');
            },
            child: const Text('Start Flipbook Mode'),
          ),
        ],
      ),
    );
  }
}
