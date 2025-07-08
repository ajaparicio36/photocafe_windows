import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassicPrintScreen extends ConsumerWidget {
  const ClassicPrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classic Print')),
      body: Center(child: const Text('Print your classic photos!')),
    );
  }
}
