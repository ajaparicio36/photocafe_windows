import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/event_pdf_preview.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/flipbook_frame_factory.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/settings/domain/data/providers/flipbook_archive_notifier.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookFrameScreen extends ConsumerStatefulWidget {
  const FlipbookFrameScreen({super.key});

  @override
  ConsumerState<FlipbookFrameScreen> createState() =>
      _FlipbookFrameScreenState();
}

class _FlipbookFrameScreenState extends ConsumerState<FlipbookFrameScreen> {
  String _selectedFrame =
      FlipbookFrameConstants.availableFrames.firstOrNull?.id ?? '';
  bool _isGeneratingPdf = false;
  String? _previewKey;
  Future<Uint8List>? _previewPdf;

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final videoState = ref.read(videoProvider).value;
      if (videoState == null || videoState.frames.isEmpty) {
        throw Exception('No frames available to generate PDF.');
      }

      final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
        (frame) => frame.id == _selectedFrame,
        orElse: () => FlipbookFrameConstants.availableFrames.first,
      );

      final pdfBytes = await FlipbookFrameFactory.generatePdfForFrame(
        frameDefinition,
        videoState.frames,
      );

      // Archive the PDF before printing (non-blocking)
      try {
        await ref
            .read(flipbookArchiveProvider.notifier)
            .saveArchive(pdfBytes, frameDefinition);
      } catch (_) {
        // Archive failure should not block printing
      }

      // Review the exact archived PDF before the customer explicitly prints.
      if (mounted) context.go('/flipbook/print', extra: pdfBytes);
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
    final frames = FlipbookFrameConstants.availableFrames;
    final busy = _isGeneratingPdf;
    return EventPage(
      title: 'Frames',
      subtitle: 'Choose a frame for your flipbook',
      onBack: busy ? null : () => context.go('/flipbook/filter'),
      child: videoState.when(
        loading: () =>
            const EventMessage(message: 'Loading your frames…', loading: true),
        error: (error, stack) => EventMessage(
          message: 'Frames could not load: $error',
          action: EventButton(
            label: 'RETURN TO FILTERS',
            onPressed: () => context.go('/flipbook/filter'),
          ),
        ),
        data: (state) {
          if (state.frames.isEmpty || frames.isEmpty)
            return EventMessage(
              message: 'Record and process a video before choosing a frame.',
              action: EventButton(
                label: 'RECORD VIDEO',
                onPressed: () => context.go('/flipbook/start'),
              ),
            );
          if (!frames.any((frame) => frame.id == _selectedFrame))
            _selectedFrame = frames.first.id;
          final definition = frames.firstWhere(
            (frame) => frame.id == _selectedFrame,
          );
          final key =
              '${definition.id}:${state.frames.map((frame) => frame.path).join('|')}';
          if (_previewKey != key) {
            _previewKey = key;
            _previewPdf = FlipbookFrameFactory.generatePdfForFrame(
              definition,
              state.frames,
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 375,
                child: EventSection(
                  title: 'Select frame',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
                          itemCount: frames.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final frame = frames[index];
                            return EventChoice(
                              title: frame.name,
                              description: frame.description,
                              selected: _selectedFrame == frame.id,
                              onTap: busy
                                  ? null
                                  : () => setState(
                                      () => _selectedFrame = frame.id,
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      EventButton(
                        label: _isGeneratingPdf
                            ? 'PREPARING…'
                            : 'PROCEED TO PRINT',
                        icon: Icons.print_outlined,
                        onPressed: busy ? null : _proceedToPrint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                child: EventSection(
                  title: 'Preview',
                  figure: 'assets/event/frames_figure1.png',
                  figureWidth: 180,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 465,
                      child: EventPanel(
                        light: true,
                        child: FutureBuilder<Uint8List>(
                          future: _previewPdf,
                          builder: (context, snapshot) {
                            if (snapshot.hasError)
                              return EventMessage(
                                message: 'Preview could not be prepared.',
                                action: EventButton(
                                  label: 'RETRY PREVIEW',
                                  onPressed: () =>
                                      setState(() => _previewKey = null),
                                ),
                              );
                            if (!snapshot.hasData)
                              return const EventMessage(
                                message:
                                    'Preparing the complete print preview…',
                                loading: true,
                              );
                            return EventPdfPreview(bytes: snapshot.data!);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
