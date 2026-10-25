import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_factory.dart';
import 'dart:io';
import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class ClassicOrganizeScreen extends ConsumerStatefulWidget {
  const ClassicOrganizeScreen({super.key});

  @override
  ConsumerState<ClassicOrganizeScreen> createState() =>
      _ClassicOrganizeScreenState();
}

class _ClassicOrganizeScreenState extends ConsumerState<ClassicOrganizeScreen> {
  String _selectedFrame = FrameConstants.availableFrames.first.id;
  bool _isGeneratingPdf = false;

  // Get available frames for current capture count
  List<FrameDefinition> get _availableFrames {
    final printerState = ref.read(printerProvider).value;
    if (printerState == null) return [];

    final FrameLayoutType currentLayout;
    if (printerState.isLandscape) {
      currentLayout = FrameLayoutType.fourLandscapePhotos;
    } else if (printerState.layoutMode == 2) {
      currentLayout = FrameLayoutType.twoPhotos;
    } else {
      currentLayout = FrameLayoutType.fourPhotos;
    }

    return FrameConstants.availableFrames
        .where((frame) => frame.supportedLayouts.contains(currentLayout))
        .toList();
  }

  Future<Uint8List> _generatePdf() async {
    final photoState = ref.read(photoProvider).value;
    final printerState = ref.read(printerProvider).value;

    if (photoState == null || photoState.photos.isEmpty) {
      throw Exception('No photos available');
    }

    if (printerState == null) {
      throw Exception('Printer settings not available');
    }

    final frameDefinition = FrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FrameConstants.availableFrames.first,
    );

    return await FrameFactory.generatePdfForFrame(
      frameDefinition,
      photoState.photos,
      printerState.layoutMode, // Use layout mode instead of capture count
      printerState.isLandscape, // Pass isLandscape flag
    );
  }

  Future<void> _proceedToPrint() async {
    if (!ref
        .read(bouncySessionProvider)
        .valid(
          ref.read(photoProvider).requireValue.photos.map((p) => p.captureId),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retake incomplete shots before printing.'),
        ),
      );
      return;
    }
    ref.read(classicBouncyFrameProvider.notifier).state = _selectedFrame;
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final session = ref.read(bouncySessionProvider);
      final generation = session.generation;
      final pdfBytes = await session.track(_generatePdf());
      if (!mounted || generation != session.generation) return;
      final printerState = ref.read(printerProvider).value;
      final isLandscape = printerState?.isLandscape ?? false;

      context.go(
        '/classic/print',
        extra: {'pdfBytes': pdfBytes, 'isLandscape': isLandscape},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoState = ref.watch(photoProvider).value;
    final printer = ref.watch(printerProvider).value;
    final photos = [...?photoState?.photos]
      ..sort((a, b) => a.index.compareTo(b.index));
    final frames = _availableFrames;
    if (frames.isNotEmpty && !frames.any((f) => f.id == _selectedFrame)) {
      _selectedFrame = frames.first.id;
    }
    final layout = printer?.isLandscape == true
        ? FrameLayoutType.fourLandscapePhotos
        : printer?.layoutMode == 2
        ? FrameLayoutType.twoPhotos
        : FrameLayoutType.fourPhotos;
    return EventPage(
      title: 'Frames',
      subtitle: 'Arrange your photos and choose a frame',
      onBack: _isGeneratingPdf ? null : () => context.go('/classic/filter'),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: EventSection(
              title: 'Drag to reorder photos',
              child: LayoutBuilder(
                builder: (context, constraints) => ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemExtent: constraints.maxHeight / 4,
                  itemCount: photos.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final changed = List<PhotoModel>.from(photos);
                    changed.insert(newIndex, changed.removeAt(oldIndex));
                    ref.read(photoProvider.notifier).reorderPhotos(changed);
                  },
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(photos[index].captureId),
                    padding: const EdgeInsets.only(bottom: 15),
                    child: EventPanel(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(photos[index].imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Click ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: EventDesign.body,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Position: ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: EventDesign.body,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            enabled: !_isGeneratingPdf,
                            child: const SizedBox(
                              width: 32,
                              height: 64,
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 28,
            child: EventSection(
              title: 'Select frame',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: frames.isEmpty
                        ? const EventMessage(
                            message:
                                'No supported frames. Return to choose another template.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
                            itemCount: frames.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final frame = frames[index];
                              return EventChoice(
                                title: frame.name,
                                description: frame.description,
                                selected: _selectedFrame == frame.id,
                                onTap: _isGeneratingPdf
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
                    label: _isGeneratingPdf ? 'PREPARING…' : 'PROCEED TO PRINT',
                    icon: Icons.print_outlined,
                    onPressed:
                        _isGeneratingPdf || photos.length != 4 || frames.isEmpty
                        ? null
                        : _proceedToPrint,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 36,
            child: EventSection(
              title: 'Preview',
              figure: 'assets/event/frames_figure1.png',
              figureWidth: 175,
              child: EventPanel(
                child: photos.length != 4 || frames.isEmpty
                    ? const Center(
                        child: Text(
                          'Capture four valid shots first.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : BouncyPreview(
                        foregroundColor: Colors.white,
                        photos: photos,
                        selections: [
                          KeychainVariantSelection(
                            frameId: _selectedFrame,
                            filterId: ref
                                .watch(bouncySessionProvider)
                                .classicFilterId,
                          ),
                        ],
                        classicLayout: layout,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
