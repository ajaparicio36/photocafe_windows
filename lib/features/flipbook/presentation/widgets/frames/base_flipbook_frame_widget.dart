import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:printing/printing.dart';

abstract class BaseFlipbookFrameWidget extends ConsumerWidget {
  final FlipbookFrameDefinition frameDefinition;

  const BaseFlipbookFrameWidget({super.key, required this.frameDefinition});

  // Abstract method that each frame must implement for PDF generation
  Future<Uint8List> generatePdf(
    List<FrameModel> frames,
    FlipbookFrameLayout layout,
  );

  // Common PDF generation logic using the frame layout
  Future<Uint8List> generatePdfFromLayout(
    List<FrameModel> frames,
    FlipbookFrameLayout layout,
  ) async {
    final pdf = pw.Document();

    // Load the frame background
    final frameImageBytes = await rootBundle.load(layout.frameAssetPath);
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    // Sort frames by index to ensure correct order
    final sortedFrames = List.from(frames)
      ..sort((a, b) => a.index.compareTo(b.index));

    // Load frame images
    final frameImages = <pw.MemoryImage>[];
    for (final frame in sortedFrames) {
      final file = File(frame.path);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        frameImages.add(pw.MemoryImage(imageBytes));
      }
    }

    // Create page format based on layout
    final pageFormat = layout.isLandscape
        ? PdfPageFormat.a6.landscape
        : PdfPageFormat.a6;

    // Generate pages with 2 frames per page
    for (int i = 0; i < frameImages.length; i += 2) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // First frame on the page
                if (i < frameImages.length)
                  _buildFrameOnPage(
                    frameImages[i],
                    frameImage,
                    layout,
                    0,
                    i + 1,
                  ),
                // Second frame on the page
                if (i + 1 < frameImages.length)
                  _buildFrameOnPage(
                    frameImages[i + 1],
                    frameImage,
                    layout,
                    1,
                    i + 2,
                  ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildFrameOnPage(
    pw.MemoryImage frameImage,
    pw.MemoryImage backgroundImage,
    FlipbookFrameLayout layout,
    int positionIndex,
    int frameNumber,
  ) {
    final yOffset = positionIndex * layout.pageHeight;
    final framePosition =
        layout.framePositions[0]; // Use first position as template

    return pw.Positioned(
      left: 0,
      top: yOffset,
      child: pw.Container(
        width: layout.pageWidth,
        height: layout.pageHeight,
        child: pw.Stack(
          children: [
            // Frame content (behind frame)
            pw.Positioned(
              left: framePosition.left,
              top: framePosition.top,
              child: pw.Image(
                frameImage,
                fit: pw.BoxFit.cover,
                width: framePosition.width,
                height: framePosition.height,
              ),
            ),
            // Frame background (on top)
            pw.Image(
              backgroundImage,
              fit: pw.BoxFit.fill,
              width: layout.pageWidth,
              height: layout.pageHeight,
            ),
            // Frame number
            pw.Positioned(
              left: 5,
              top: layout.pageHeight / 2 - 10,
              child: pw.Text(
                '$frameNumber',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Common build method for all frames
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoStateAsync = ref.watch(videoProvider);

    return videoStateAsync.when(
      data: (videoState) {
        if (videoState.frames.isEmpty) {
          return const Center(child: Text('No frames to display.'));
        }

        return FutureBuilder<Uint8List>(
          key: ValueKey('${frameDefinition.id}_${videoState.frames.length}'),
          future: generatePdf(videoState.frames, frameDefinition.layout),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating ${frameDefinition.name} preview...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${videoState.frames.length} frames • ${(videoState.frames.length / 2).ceil()} pages',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              return PdfPreview(
                key: ValueKey('preview_${frameDefinition.id}'),
                build: (format) => snapshot.data!,
                allowSharing: false,
                allowPrinting: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 700,
                pdfPreviewPageDecoration: const BoxDecoration(
                  color: Colors.white,
                ),
                previewPageMargin: const EdgeInsets.all(4),
                padding: EdgeInsets.zero,
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error generating ${frameDefinition.name} preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild by changing the key
                        ref.invalidate(videoProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing preview...'),
                  ],
                ),
              );
            }
          },
        );
      },
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
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading frames: $error'),
          ],
        ),
      ),
    );
  }
}
