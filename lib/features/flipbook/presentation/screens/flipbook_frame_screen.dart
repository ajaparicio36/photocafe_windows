import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlipbookFrameScreen extends ConsumerWidget {
  const FlipbookFrameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flipbook Frame')),
      body: Center(child: const Text('Capture your flipbook moments!')),
    );
  }
}
