import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:printing/printing.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';

abstract class BaseFrameWidget extends ConsumerWidget {
  final FrameDefinition frameDefinition;

  const BaseFrameWidget({super.key, required this.frameDefinition});

  // Abstract method that each frame must implement for PDF generation
  Future<Uint8List> generatePdf(
    List<PhotoModel> photos,
    int captureCount,
    FrameLayout layout,
  );

  // Common PDF generation logic using the frame layout
  Future<Uint8List> generatePdfFromLayout(
    List<PhotoModel> photos,
    int captureCount,
    FrameLayout layout,
  ) async {
    final pdf = pw.Document();

    // Load the frame background
    final frameImageBytes = await rootBundle.load(layout.frameAssetPath);
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    // Sort photos by index to ensure correct order
    final sortedPhotos = List.from(photos)
      ..sort((a, b) => a.index.compareTo(b.index));

    // Load captured photo images
    final photoImages = <pw.MemoryImage>[];
    for (final photo in sortedPhotos) {
      final file = File(photo.imagePath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        photoImages.add(pw.MemoryImage(imageBytes));
      }
    }

    // Fallback to test image if no photos available
    pw.MemoryImage? testImage;
    if (photoImages.isEmpty) {
      try {
        final testImageBytes = await rootBundle.load('assets/frames/test.jpg');
        testImage = pw.MemoryImage(testImageBytes.buffer.asUint8List());
      } catch (e) {
        print('Test image not found: $e');
      }
    }

    final photoCount = captureCount == 2 ? 2 : 4;
    final leftPositions = layout.leftColumnPositions;
    final rightPositions = layout.rightColumnPositions;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Left column images
              for (int i = 0; i < photoCount && i < leftPositions.length; i++)
                pw.Positioned(
                  left: leftPositions[i].left,
                  top: leftPositions[i].top,
                  child: pw.Container(
                    width: leftPositions[i].width,
                    height: leftPositions[i].height,
                    child: _buildPhotoWidget(i, photoImages, testImage),
                  ),
                ),
              // Right column images (duplicates)
              for (int i = 0; i < photoCount && i < rightPositions.length; i++)
                pw.Positioned(
                  left: rightPositions[i].left,
                  top: rightPositions[i].top,
                  child: pw.Container(
                    width: rightPositions[i].width,
                    height: rightPositions[i].height,
                    child: _buildPhotoWidget(i, photoImages, testImage),
                  ),
                ),
              // Frame overlay on top
              pw.Positioned.fill(
                child: pw.Image(frameImage, fit: pw.BoxFit.fill),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPhotoWidget(
    int index,
    List<pw.MemoryImage> photoImages,
    pw.MemoryImage? testImage,
  ) {
    if (photoImages.length > index) {
      return pw.Image(photoImages[index], fit: pw.BoxFit.cover);
    } else if (testImage != null) {
      return pw.Image(testImage, fit: pw.BoxFit.cover);
    } else {
      return pw.Container(
        color: PdfColors.grey300,
        child: pw.Center(
          child: pw.Text(
            'Photo ${index + 1}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      );
    }
  }

  // Common build method for all frames
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoStateAsync = ref.watch(photoProvider);

    return photoStateAsync.when(
      data: (photoState) {
        final currentLayoutType = photoState.captureCount == 2
            ? FrameLayoutType.twoPhotos
            : FrameLayoutType.fourPhotos;

        final layout = frameDefinition.layouts[currentLayoutType];

        if (layout == null) {
          return const Center(
            child: Text('Layout not supported for this frame'),
          );
        }

        return FutureBuilder<Uint8List>(
          future: generatePdf(
            photoState.photos,
            photoState.captureCount,
            layout,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return PdfPreview(
                build: (format) => snapshot.data!,
                allowSharing: false,
                allowPrinting: false,
                canChangeOrientation: false,
                initialPageFormat: PdfPageFormat.a6,
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
                    Text('Error generating PDF: ${snapshot.error}'),
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
                    Text('Generating preview...'),
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading photos: $error'),
          ],
        ),
      ),
    );
  }
}
