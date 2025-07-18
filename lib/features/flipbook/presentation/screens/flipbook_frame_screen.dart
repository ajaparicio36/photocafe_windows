import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/frame_one.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookFrameScreen extends ConsumerStatefulWidget {
  const FlipbookFrameScreen({super.key});

  @override
  ConsumerState<FlipbookFrameScreen> createState() =>
      _FlipbookFrameScreenState();
}

class _FlipbookFrameScreenState extends ConsumerState<FlipbookFrameScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final videoState = ref.read(videoProvider).value;
      if (videoState == null || videoState.frames.isEmpty) {
        throw Exception('No frames available to generate PDF.');
      }

      // Generate the PDF using the helper method from the frame widget
      final pdfBytes = await FlipbookFrameOne.generatePdf(videoState.frames);

      context.go('/flipbook/print', extra: pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);

    return ScreenContainer(
      child: Column(
        children: [
          const ScreenHeader(
            title: 'Apply a Frame',
            subtitle: 'Preview your flipbook pages',
            backRoute: '/flipbook/filter',
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              children: [
                // Left Panel: Frame Selection (placeholder for now)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Frame',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // For now, only one frame is available
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: const ListTile(
                            title: Text(
                              'Flipbook Frame',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'A simple frame for your flipbook pages.',
                            ),
                            leading: Icon(Icons.check_box),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 80,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : _proceedToPrint,
                            icon: _isGeneratingPdf
                                ? const SizedBox.shrink()
                                : const Icon(Icons.print_rounded, size: 32),
                            label: _isGeneratingPdf
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Proceed to Print',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Right Panel: Preview
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: videoState.when(
                            data: (state) => state.frames.isNotEmpty
                                ? const FlipbookFrameOne()
                                : const Center(
                                    child: Text('No frames to preview.'),
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, s) => Center(child: Text('Error: $e')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
