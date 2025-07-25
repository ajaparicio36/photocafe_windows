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

  pw.Widget _buildFrameOnPage(
    pw.MemoryImage frameImage,
    pw.MemoryImage? frameBackgroundImage, // Pre-loaded background
    FlipbookFrameLayout layout,
    int positionIndex,
    int frameNumber,
  ) {
    final halfPageHeight = layout.pageHeight / 2;
    final yOffset = positionIndex * halfPageHeight;
    final framePosition =
        layout.framePositions[0]; // Use first position as template

    // Scale frame position for half-page height
    final scaledFramePosition = FlipbookFramePosition(
      left: framePosition.left,
      top: framePosition.top * 0.5, // Scale for half page
      width: framePosition.width,
      height: framePosition.height * 0.5, // Scale for half page
    );

    return pw.Positioned(
      left: 0,
      top: yOffset,
      child: pw.Container(
        width: layout.pageWidth,
        height: halfPageHeight,
        child: pw.Stack(
          children: [
            // White background
            pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),

            // Frame content (behind frame background)
            pw.Positioned(
              left: scaledFramePosition.left,
              top: scaledFramePosition.top,
              child: pw.Container(
                width: scaledFramePosition.width,
                height: scaledFramePosition.height,
                child: pw.Image(frameImage, fit: pw.BoxFit.cover),
              ),
            ),

            // Frame background/border (on top of content)
            if (frameBackgroundImage != null)
              pw.Positioned.fill(
                child: pw.Image(frameBackgroundImage, fit: pw.BoxFit.fill),
              ),

            // Frame number
            pw.Positioned(
              left: 5,
              bottom: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(2),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  '$frameNumber',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Common PDF generation logic using the frame layout
  Future<Uint8List> generatePdfFromLayout(
    List<FrameModel> frames,
    FlipbookFrameLayout layout,
  ) async {
    final pdf = pw.Document();

    // Sort frames by index to ensure correct order
    final sortedFrames = List<FrameModel>.from(frames)
      ..sort((a, b) => a.index.compareTo(b.index));

    print('Generating PDF with ${sortedFrames.length} frames for flipbook');

    // Ensure we have exactly 100 frames for 50-page flipbook
    final targetFrameCount = 100;
    List<FrameModel> processedFrames;

    if (sortedFrames.length < targetFrameCount) {
      print(
        'Warning: Only ${sortedFrames.length} frames available, expected $targetFrameCount',
      );
      // Duplicate frames to reach target count
      processedFrames = List<FrameModel>.from(sortedFrames);
      while (processedFrames.length < targetFrameCount) {
        final framesToAdd = (targetFrameCount - processedFrames.length).clamp(
          0,
          sortedFrames.length,
        );
        processedFrames.addAll(sortedFrames.take(framesToAdd));
      }
    } else if (sortedFrames.length > targetFrameCount) {
      print(
        'Trimming ${sortedFrames.length} frames to exactly $targetFrameCount',
      );
      processedFrames = sortedFrames.take(targetFrameCount).toList();
    } else {
      processedFrames = sortedFrames;
    }

    // Load the frame background image once
    pw.MemoryImage? frameBackgroundImage;
    try {
      final frameImageBytes = await rootBundle.load(layout.frameAssetPath);
      frameBackgroundImage = pw.MemoryImage(
        frameImageBytes.buffer.asUint8List(),
      );
      print('Successfully loaded frame background: ${layout.frameAssetPath}');
    } catch (e) {
      print('Warning: Could not load frame asset ${layout.frameAssetPath}: $e');
    }

    // Load frame images
    final frameImages = <pw.MemoryImage>[];
    for (final frame in processedFrames) {
      final file = File(frame.path);
      if (await file.exists()) {
        try {
          final imageBytes = await file.readAsBytes();
          frameImages.add(pw.MemoryImage(imageBytes));
        } catch (e) {
          print('Error loading frame image ${frame.path}: $e');
          // Skip this frame if it can't be loaded
        }
      } else {
        print('Frame file not found: ${frame.path}');
      }
    }

    print('Loaded ${frameImages.length} frame images for PDF generation');

    // Use A6 landscape format
    final pageFormat = const PdfPageFormat(
      6 * PdfPageFormat.inch,
      4 * PdfPageFormat.inch,
    );

    // Generate 50 pages with 2 frames per page
    final totalPages = 50;
    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final frameIndex1 = pageIndex * 2;
      final frameIndex2 = pageIndex * 2 + 1;

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // First frame on the page (top half)
                if (frameIndex1 < frameImages.length)
                  _buildFrameOnPage(
                    frameImages[frameIndex1],
                    frameBackgroundImage,
                    layout,
                    0, // Position index (top half)
                    frameIndex1 + 1, // Frame number (1-based)
                  ),
                // Second frame on the page (bottom half)
                if (frameIndex2 < frameImages.length)
                  _buildFrameOnPage(
                    frameImages[frameIndex2],
                    frameBackgroundImage,
                    layout,
                    1, // Position index (bottom half)
                    frameIndex2 + 1, // Frame number (1-based)
                  ),
              ],
            );
          },
        ),
      );
    }

    print('Generated PDF with $totalPages pages for flipbook (A6 landscape)');
    return pdf.save();
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
