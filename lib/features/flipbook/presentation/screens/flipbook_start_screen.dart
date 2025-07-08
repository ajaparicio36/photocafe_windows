import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlipbookStartScreen extends ConsumerWidget {
  const FlipbookStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flipbook Start')),
      body: Center(child: const Text('Start your flipbook journey!')),
    );
  }
}
