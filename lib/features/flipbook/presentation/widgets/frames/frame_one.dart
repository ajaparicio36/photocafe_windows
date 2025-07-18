import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:printing/printing.dart';

class FlipbookFrameOne extends ConsumerWidget {
  const FlipbookFrameOne({super.key});

  // Static method to allow calling from outside the widget
  static Future<Uint8List> generatePdf(List<FrameModel> frames) async {
    final pdf = pw.Document();
    final frameImageBytes = await rootBundle.load('assets/flipbook/frame1.png');
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    final sortedFrames = List.from(frames)
      ..sort((a, b) => a.index.compareTo(b.index));

    final frameImages = <pw.MemoryImage>[];
    for (final frame in sortedFrames) {
      final file = File(frame.path);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        frameImages.add(pw.MemoryImage(imageBytes));
      }
    }

    // A6 landscape format
    final pageFormat = PdfPageFormat.a6.landscape;
    const frameWidth = 190.0;
    const frameHeight = 120.0;
    final horizontalMargin = (pageFormat.width - (frameWidth * 2)) / 3;
    final verticalMargin = (pageFormat.height - frameHeight) / 2;

    for (int i = 0; i < frameImages.length; i += 2) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                // First frame on the page
                if (i < frameImages.length)
                  pw.Container(
                    width: frameWidth,
                    height: frameHeight,
                    margin: pw.EdgeInsets.symmetric(
                      vertical: verticalMargin,
                      horizontal: horizontalMargin,
                    ),
                    child: pw.Stack(
                      alignment: pw.Alignment.center,
                      children: [
                        pw.Image(
                          frameImages[i],
                          fit: pw.BoxFit.cover,
                          width: frameWidth,
                          height: frameHeight,
                        ),
                        pw.Image(
                          frameImage,
                          fit: pw.BoxFit.fill,
                          width: frameWidth,
                          height: frameHeight,
                        ),
                      ],
                    ),
                  ),
                // Second frame on the page
                if (i + 1 < frameImages.length)
                  pw.Container(
                    width: frameWidth,
                    height: frameHeight,
                    margin: pw.EdgeInsets.symmetric(
                      vertical: verticalMargin,
                      horizontal: horizontalMargin,
                    ),
                    child: pw.Stack(
                      alignment: pw.Alignment.center,
                      children: [
                        pw.Image(
                          frameImages[i + 1],
                          fit: pw.BoxFit.cover,
                          width: frameWidth,
                          height: frameHeight,
                        ),
                        pw.Image(
                          frameImage,
                          fit: pw.BoxFit.fill,
                          width: frameWidth,
                          height: frameHeight,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }
    return pdf.save();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoProvider).value;

    if (videoState == null || videoState.frames.isEmpty) {
      return const Center(child: Text('No frames to display.'));
    }

    return FutureBuilder<Uint8List>(
      future: generatePdf(videoState.frames),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error generating preview: ${snapshot.error}'),
          );
        }
        if (snapshot.hasData) {
          return PdfPreview(
            build: (format) => snapshot.data!,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
          );
        }
        return const Center(child: Text('Generating preview...'));
      },
    );
  }
}
