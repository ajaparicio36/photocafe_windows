import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlipbookPrintScreen extends ConsumerWidget {
  const FlipbookPrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flipbook Print')),
      body: Center(child: const Text('Print your flipbook photos!')),
    );
  }
}
