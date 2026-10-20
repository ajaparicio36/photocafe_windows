import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_artwork_loader.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/design/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to filters',
                      onPressed: () => context.go('/classic/filter'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Arrange your photos',
                        style: TextStyle(color: Colors.white, fontSize: 26),
                      ),
                    ),
                    FilledButton(
                      onPressed: _isGeneratingPdf || photos.length != 4
                          ? null
                          : _proceedToPrint,
                      child: Text(
                        _isGeneratingPdf
                            ? 'Preparing print…'
                            : 'Proceed to print',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Drag photos to reorder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) =>
                                    ReorderableListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemExtent: constraints.maxHeight / 4,
                                      itemCount: photos.length,
                                      onReorder: (oldIndex, newIndex) {
                                        if (newIndex > oldIndex) newIndex--;
                                        final changed = List<PhotoModel>.from(
                                          photos,
                                        );
                                        changed.insert(
                                          newIndex,
                                          changed.removeAt(oldIndex),
                                        );
                                        ref
                                            .read(photoProvider.notifier)
                                            .reorderPhotos(changed);
                                      },
                                      itemBuilder: (context, index) => Padding(
                                        key: ValueKey(photos[index].captureId),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Image.file(
                                                File(photos[index].imagePath),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Text(
                                              'Photo ${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                          ],
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Select frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: frames.isEmpty ? null : _selectedFrame,
                              dropdownColor: const Color(0xff740000),
                              style: const TextStyle(color: Colors.white),
                              items: frames
                                  .map(
                                    (frame) => DropdownMenuItem(
                                      value: frame.id,
                                      child: Text(frame.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isGeneratingPdf
                                  ? null
                                  : (id) =>
                                        setState(() => _selectedFrame = id!),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: frames.isEmpty
                                  ? const Text('No supported frames')
                                  : FutureBuilder<ByteData>(
                                      future: FrameArtworkLoader.load(
                                        frames
                                            .firstWhere(
                                              (f) => f.id == _selectedFrame,
                                            )
                                            .layouts[layout]!
                                            .frameAssetPath,
                                      ),
                                      builder: (context, snapshot) =>
                                          snapshot.hasData
                                          ? Image.memory(
                                              snapshot.data!.buffer.asUint8List(
                                                snapshot.data!.offsetInBytes,
                                                snapshot.data!.lengthInBytes,
                                              ),
                                              fit: BoxFit.contain,
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: photos.length != 4
                              ? const Center(
                                  child: Text(
                                    'Capture four valid shots first.',
                                  ),
                                )
                              : BouncyPreview(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
