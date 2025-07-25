import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
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
    int layoutMode, // Changed from captureCount to layoutMode
    FrameLayout layout,
  ) async {
    final pdf = pw.Document();

    final frameImageBytes = await rootBundle.load(layout.frameAssetPath);
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    final sortedPhotos = List.from(photos)
      ..sort((a, b) => a.index.compareTo(b.index));

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

    final leftPositions = layout.leftColumnPositions;
    final rightPositions = layout.rightColumnPositions;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          4 * PdfPageFormat.inch,
          6 * PdfPageFormat.inch,
        ),
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Left column images (photos 1 and 2 for 2x2, all 4 for 4x4)
              pw.Positioned.fill(child: pw.Container(color: PdfColors.black)),
              for (int i = 0; i < leftPositions.length; i++)
                pw.Positioned(
                  left: leftPositions[i].left,
                  top: leftPositions[i].top,
                  child: pw.Container(
                    width: leftPositions[i].width,
                    height: leftPositions[i].height,
                    child: _buildPhotoWidget(
                      i,
                      photoImages,
                      testImage,
                      leftPositions[i].rotationDegrees,
                    ),
                  ),
                ),
              // Right column images (photos 3 and 4 for 2x2, duplicates for 4x4)
              for (int i = 0; i < rightPositions.length; i++)
                pw.Positioned(
                  left: rightPositions[i].left,
                  top: rightPositions[i].top,
                  child: pw.Container(
                    width: rightPositions[i].width,
                    height: rightPositions[i].height,
                    child: _buildPhotoWidget(
                      layoutMode == 2
                          ? i + 2
                          : i, // For 2x2 use photos 3,4; for 4x4 use duplicates
                      photoImages,
                      testImage,
                      rightPositions[i].rotationDegrees,
                    ),
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
    double rotationDegrees,
  ) {
    pw.Widget imageWidget;

    if (photoImages.length > index) {
      imageWidget = pw.Image(photoImages[index], fit: pw.BoxFit.cover);
    } else if (testImage != null) {
      imageWidget = pw.Image(testImage, fit: pw.BoxFit.cover);
    } else {
      imageWidget = pw.Container(
        color: PdfColors.grey300,
        child: pw.Center(
          child: pw.Text(
            'Photo ${index + 1}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      );
    }

    // Apply rotation if specified
    if (rotationDegrees != 0.0) {
      final radiansRotation = rotationDegrees * (3.14159265359 / 180.0);
      return pw.Transform.rotate(angle: radiansRotation, child: imageWidget);
    }

    return imageWidget;
  }

  // Method to generate PDF with custom rotations for each photo
  Future<Uint8List> generatePdfFromLayoutWithRotations(
    List<PhotoModel> photos,
    int layoutMode, // Changed from captureCount to layoutMode
    FrameLayout layout,
    List<double> rotationsDegrees,
  ) async {
    final pdf = pw.Document();

    final frameImageBytes = await rootBundle.load(layout.frameAssetPath);
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    final sortedPhotos = List.from(photos)
      ..sort((a, b) => a.index.compareTo(b.index));

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

    final leftPositions = layout.leftColumnPositions;
    final rightPositions = layout.rightColumnPositions;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          4 * PdfPageFormat.inch,
          6 * PdfPageFormat.inch,
        ),
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Left column images
              pw.Positioned.fill(child: pw.Container(color: PdfColors.black)),
              for (int i = 0; i < leftPositions.length; i++)
                pw.Positioned(
                  left: leftPositions[i].left,
                  top: leftPositions[i].top,
                  child: pw.Container(
                    width: leftPositions[i].width,
                    height: leftPositions[i].height,
                    child: _buildPhotoWidget(
                      i,
                      photoImages,
                      testImage,
                      i < rotationsDegrees.length ? rotationsDegrees[i] : 0.0,
                    ),
                  ),
                ),
              for (int i = 0; i < rightPositions.length; i++)
                pw.Positioned(
                  left: rightPositions[i].left,
                  top: rightPositions[i].top,
                  child: pw.Container(
                    width: rightPositions[i].width,
                    height: rightPositions[i].height,
                    child: _buildPhotoWidget(
                      layoutMode == 2
                          ? i + 2
                          : i, // For 2x2 use photos 3,4; for 4x4 use duplicates
                      photoImages,
                      testImage,
                      (layoutMode == 2 ? i + 2 : i) < rotationsDegrees.length
                          ? rotationsDegrees[layoutMode == 2 ? i + 2 : i]
                          : 0.0,
                    ),
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

  // Common build method for all frames
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoStateAsync = ref.watch(photoProvider);
    final printerStateAsync = ref.watch(printerProvider);

    return photoStateAsync.when(
      data: (photoState) {
        return printerStateAsync.when(
          data: (printerState) {
            final currentLayoutType = printerState.layoutMode == 2
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
                printerState
                    .layoutMode, // Use layout mode instead of capture count
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
          error: (error, stack) =>
              Center(child: Text('Error loading printer settings: $error')),
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
