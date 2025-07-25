import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/flipbook_frame_factory.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookFrameScreen extends ConsumerStatefulWidget {
  const FlipbookFrameScreen({super.key});

  @override
  ConsumerState<FlipbookFrameScreen> createState() =>
      _FlipbookFrameScreenState();
}

class _FlipbookFrameScreenState extends ConsumerState<FlipbookFrameScreen> {
  String _selectedFrame = 'standard_frame'; // Default to standard frame
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

      // Get the selected frame definition
      final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
        (frame) => frame.id == _selectedFrame,
        orElse: () => FlipbookFrameConstants.availableFrames.first,
      );

      // Use the frame factory to generate PDF
      final pdfBytes = await FlipbookFrameFactory.generatePdfForFrame(
        frameDefinition,
        videoState.frames,
      );

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

  Widget _buildFrameSelector() {
    final availableFrames = FlipbookFrameConstants.availableFrames;

    return Column(
      children: availableFrames.map((frame) {
        final isSelected = _selectedFrame == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: frame.id,
                groupValue: _selectedFrame,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFrame = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frame.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      frame.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFramePreview() {
    // Get the selected frame definition
    final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FlipbookFrameConstants.availableFrames.first,
    );

    // Use the frame factory to create the preview widget with a key to force rebuilds
    return Container(
      key: ValueKey('preview_container_$_selectedFrame'),
      child: FlipbookFrameFactory.createFrameWidget(frameDefinition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);

    return ScreenContainer(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Apply a Frame',
            subtitle: videoState.hasValue && videoState.value!.frames.isNotEmpty
                ? 'Choose a frame for your ${videoState.value!.frames.length}-frame flipbook (${(videoState.value!.frames.length / 2).ceil()} pages)'
                : 'Choose a frame for your flipbook pages',
            backRoute: '/flipbook/filter',
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              children: [
                // Left Panel: Frame Selection
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
                        Row(
                          children: [
                            Icon(
                              Icons.crop_free_rounded,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Select Frame',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Dynamic frame selector
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildFrameSelector(),
                          ),
                        ),

                        const SizedBox(height: 24),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            key: ValueKey('preview_wrapper_$_selectedFrame'),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: videoState.when(
                                data: (state) => state.frames.isNotEmpty
                                    ? _buildFramePreview()
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_library_outlined,
                                              size: 48,
                                            ),
                                            SizedBox(height: 16),
                                            Text('No frames to preview.'),
                                          ],
                                        ),
                                      ),
                                loading: () => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Loading frames...'),
                                    ],
                                  ),
                                ),
                                error: (e, s) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Error: $e'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
