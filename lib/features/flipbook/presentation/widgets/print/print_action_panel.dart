import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookPrintActionPanel extends ConsumerWidget {
  final bool isPrinting;
  final VoidCallback onPrint;

  const FlipbookPrintActionPanel({
    super.key,
    required this.isPrinting,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 100,
            child: ElevatedButton.icon(
              onPressed: isPrinting ? null : onPrint,
              icon: isPrinting
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.print_rounded, size: 32),
              label: Text(
                isPrinting ? 'Printing...' : 'Print Flipbook',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: TextButton.icon(
              onPressed: isPrinting
                  ? null
                  : () {
                      ref.read(videoProvider.notifier).clearVideo();
                      context.go('/');
                    },
              icon: const Icon(Icons.refresh_rounded, size: 32),
              label: const Text('Start Over', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }
}
