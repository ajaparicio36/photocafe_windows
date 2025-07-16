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

class FrameOne extends ConsumerWidget {
  const FrameOne({super.key});

  Future<Uint8List> _generatePdf(
    List<PhotoModel> photos,
    int captureCount,
  ) async {
    final pdf = pw.Document();

    // Load the frame background
    final frameImageBytes = await rootBundle.load('assets/frames/frame1.png');
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
        // If test image is not available, create a placeholder
        print('Test image not found: $e');
      }
    }

    final int photoCount = captureCount == 2 ? 2 : 4;
    final double topOffset = captureCount == 2 ? 100 : 15;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Images below (left column)
              for (int i = 0; i < photoCount; i++)
                pw.Positioned(
                  left: 13,
                  top: topOffset + i * 92.5,
                  child: pw.Container(
                    width: 125,
                    height: 78,
                    child: photoImages.length > i
                        ? pw.Image(
                            photoImages[i],
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : testImage != null
                        ? pw.Image(
                            testImage,
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : pw.Container(
                            color: PdfColors.grey300,
                            child: pw.Center(
                              child: pw.Text(
                                'Photo ${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              // Images below (right column - duplicates)
              for (int i = 0; i < photoCount; i++)
                pw.Positioned(
                  left: 161,
                  top: topOffset + i * 92.72,
                  child: pw.Container(
                    width: 125,
                    height: 78,
                    child: photoImages.length > i
                        ? pw.Image(
                            photoImages[i],
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : testImage != null
                        ? pw.Image(
                            testImage,
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : pw.Container(
                            color: PdfColors.grey300,
                            child: pw.Center(
                              child: pw.Text(
                                'Photo ${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoStateAsync = ref.watch(photoProvider);

    return photoStateAsync.when(
      data: (photoState) {
        return FutureBuilder<Uint8List>(
          future: _generatePdf(photoState.photos, photoState.captureCount),
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
