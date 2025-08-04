import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows_printer/windows_printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:pdf/widgets.dart' as pw;

class PrinterNotifier extends AsyncNotifier<PrinterState> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<PrinterState> build() async {
    final availablePrinters = await getAvailablePrinters();
    final prefs = await _prefs;
    final cutEnabledPrinter = prefs.getString('cutEnabledPrinter');
    final cutDisabledPrinter = prefs.getString('cutDisabledPrinter');
    final videoPrinter = prefs.getString('videoPrinter');
    final photoCameraName = prefs.getString('photoCameraName');
    final videoCameraName = prefs.getString('videoCameraName');
    final layoutMode = prefs.getInt('layoutMode') ?? 4; // Default to 4x4
    final isFullscreen = prefs.getBool('isFullscreen') ?? false;

    return PrinterState(
      cutEnabledPrinter: availablePrinters.contains(cutEnabledPrinter)
          ? cutEnabledPrinter
          : null,
      cutDisabledPrinter: availablePrinters.contains(cutDisabledPrinter)
          ? cutDisabledPrinter
          : null,
      videoPrinter: availablePrinters.contains(videoPrinter)
          ? videoPrinter
          : null,
      photoCameraName: photoCameraName,
      videoCameraName: videoCameraName,
      layoutMode: layoutMode,
      isFullscreen: isFullscreen,
    );
  }

  Future<List<String>> getAvailablePrinters() async {
    try {
      final printers = await WindowsPrinter.getAvailablePrinters();
      return printers;
    } catch (e) {
      return [];
    }
  }

  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      return cameras;
    } catch (e) {
      return [];
    }
  }

  Future<void> setCutEnabledPrinter(String printerName) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setString('cutEnabledPrinter', printerName);
        return state.value!.copyWith(
          cutEnabledPrinter: printerName,
          error: null,
        );
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setCutDisabledPrinter(String printerName) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setString('cutDisabledPrinter', printerName);
        return state.value!.copyWith(
          cutDisabledPrinter: printerName,
          error: null,
        );
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setVideoPrinter(String printerName) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setString('videoPrinter', printerName);
        return state.value!.copyWith(videoPrinter: printerName, error: null);
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setPhotoCameraName(String cameraName) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setString('photoCameraName', cameraName);
        return state.value!.copyWith(photoCameraName: cameraName, error: null);
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setVideoCameraName(String cameraName) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setString('videoCameraName', cameraName);
        return state.value!.copyWith(videoCameraName: cameraName, error: null);
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setLayoutMode(int mode) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setInt('layoutMode', mode);
        return state.value!.copyWith(layoutMode: mode, error: null);
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> setFullscreenMode(bool isFullscreen) async {
    state = await AsyncValue.guard(() async {
      try {
        final prefs = await _prefs;
        await prefs.setBool('isFullscreen', isFullscreen);

        // Apply fullscreen setting immediately
        if (isFullscreen) {
          await windowManager.setFullScreen(true);
        } else {
          await windowManager.setFullScreen(false);
        }

        return state.value!.copyWith(isFullscreen: isFullscreen, error: null);
      } catch (e) {
        return state.value!.copyWith(error: e.toString());
      }
    });
  }

  Future<void> printPdfBytes(
    Uint8List pdfBytes, {
    bool cut = false,
    int copies = 1,
  }) async {
    final printerName = cut
        ? state.value?.cutEnabledPrinter
        : state.value?.cutDisabledPrinter;

    if (printerName == null || printerName.isEmpty) {
      throw Exception('No printer selected for this action.');
    }

    // Method 2: Try using the system's default PDF handler via temp file
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'photobooth_print_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      await tempFile.writeAsBytes(pdfBytes);
      // Use process run but with PDFtoPrinter
      final result = await Process.run('cmd.exe', [
        '/c',
        'PDFtoPrinter',
        '/s',
        tempFile.path,
        printerName,
        copies.toString(),
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception('Failed to print PDF: ${result.stderr}');
      }

      return;
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }

  Future<void> printPdfBytesForVideo(Uint8List pdfBytes) async {
    final printerName = state.value?.videoPrinter;

    if (printerName == null || printerName.isEmpty) {
      throw Exception('No video printer selected.');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'photobooth_video_print_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      await tempFile.writeAsBytes(pdfBytes);

      final result = await Process.run('cmd.exe', [
        '/c',
        'PDFtoPrinter',
        '/s',
        tempFile.path,
        printerName,
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception(
          'Failed to print PDF to video printer: ${result.stderr}',
        );
      }

      return;
    } catch (e) {
      throw Exception('Failed to print PDF to video printer: $e');
    }
  }

  Future<void> testPrintClassicFrame() async {
    final printerName = state.value?.cutDisabledPrinter;

    if (printerName == null || printerName.isEmpty) {
      throw Exception('No cut disabled printer selected for test print.');
    }

    try {
      // Generate PDF with just the frame border (no photos)
      final pdfBytes = await _generateClassicFrameTestPdf();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'classic_frame_test_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      await tempFile.writeAsBytes(pdfBytes);

      final result = await Process.run('cmd.exe', [
        '/c',
        'PDFtoPrinter',
        '/s',
        tempFile.path,
        printerName,
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception('Failed to print classic frame test: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to print classic frame test: $e');
    }
  }

  Future<void> testPrintFlipbookFrame() async {
    final printerName = state.value?.cutDisabledPrinter;

    if (printerName == null || printerName.isEmpty) {
      throw Exception('No cut disabled printer selected for test print.');
    }

    try {
      // Generate PDF with just the flipbook frame border (no content)
      final pdfBytes = await _generateFlipbookFrameTestPdf();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'flipbook_frame_test_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      await tempFile.writeAsBytes(pdfBytes);

      final result = await Process.run('cmd.exe', [
        '/c',
        'PDFtoPrinter',
        '/s',
        tempFile.path,
        printerName,
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception(
          'Failed to print flipbook frame test: ${result.stderr}',
        );
      }
    } catch (e) {
      throw Exception('Failed to print flipbook frame test: $e');
    }
  }

  Future<Uint8List> _generateClassicFrameTestPdf() async {
    final pdf = pw.Document();

    // Use the first 4x4 frame for testing
    const frameAssetPath = 'assets/frames/frame1.png';
    final frameImageBytes = await rootBundle.load(frameAssetPath);
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    // DNP DS-RX1HS specific dimensions with bleed compensation
    const double bleedMm = 3.0;
    const double bleedPoints = bleedMm * 2.834645669;
    const double originalWidth = 4 * PdfPageFormat.inch;
    const double originalHeight = 6 * PdfPageFormat.inch;
    const double adjustedWidth = originalWidth + (bleedPoints * 2);
    const double adjustedHeight = originalHeight + (bleedPoints * 3);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(adjustedWidth, adjustedHeight),
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          const double scaleFactor = 0.94;
          const double offsetX = bleedPoints * 0.5; // Reduced to move right
          const double offsetY = bleedPoints * -0.92; // Increased to move up

          return pw.Transform.scale(
            scale: scaleFactor,
            child: pw.Transform.translate(
              offset: const PdfPoint(-offsetX, -offsetY),
              child: pw.Stack(
                children: [
                  // White background
                  pw.Positioned.fill(
                    child: pw.Container(color: PdfColors.white),
                  ),
                  // Test pattern to show photo areas
                  ..._buildTestPatternForClassicFrame(),
                  // Frame overlay on top
                  pw.Positioned.fill(
                    child: pw.Transform.scale(
                      scale: 1.005,
                      child: pw.Image(frameImage, fit: pw.BoxFit.fill),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildTestPatternForClassicFrame() {
    // Use frame 1 positions from constants
    const leftPositions = [
      FramePhotoPosition(left: 13, top: 13, width: 125, height: 83),
      FramePhotoPosition(left: 13, top: 107.5, width: 125, height: 83),
      FramePhotoPosition(left: 13, top: 204, width: 125, height: 83),
      FramePhotoPosition(left: 13, top: 300, width: 125, height: 83),
    ];
    const rightPositions = [
      FramePhotoPosition(left: 156, top: 13, width: 125, height: 83),
      FramePhotoPosition(left: 156, top: 107.5, width: 125, height: 83),
      FramePhotoPosition(left: 156, top: 204, width: 125, height: 83),
      FramePhotoPosition(left: 156, top: 300, width: 125, height: 83),
    ];

    final List<pw.Widget> widgets = [];

    // Add left column test patterns
    for (int i = 0; i < leftPositions.length; i++) {
      widgets.add(
        pw.Positioned(
          left: leftPositions[i].left,
          top: leftPositions[i].top,
          child: pw.Container(
            width: leftPositions[i].width,
            height: leftPositions[i].height,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.red, width: 1),
            ),
            child: pw.Center(
              child: pw.Text(
                'L${i + 1}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add right column test patterns
    for (int i = 0; i < rightPositions.length; i++) {
      widgets.add(
        pw.Positioned(
          left: rightPositions[i].left,
          top: rightPositions[i].top,
          child: pw.Container(
            width: rightPositions[i].width,
            height: rightPositions[i].height,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.blue, width: 1),
            ),
            child: pw.Center(
              child: pw.Text(
                'R${i + 1}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<pw.Widget> _buildTestPatternForFlipbookFrame() {
    // Use flipbook frame 1 positions from constants
    const framePosition = FlipbookFramePosition(
      left: 215.0,
      top: 20.0,
      width: 220,
      height: 248,
    );

    // A6 landscape dimensions: 432 x 288 points
    const pageHeight = 288.0;
    final halfPageHeight = pageHeight / 2; // 144 points

    return [
      // First frame area (top half of page)
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.Container(
          width: 432, // Full page width
          height: halfPageHeight,
          child: pw.Stack(
            children: [
              // White background for first frame
              pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
              // Test pattern for first frame content area
              pw.Positioned(
                left: framePosition.left,
                top: framePosition.top * 0.5,
                child: pw.Container(
                  width: framePosition.width,
                  height: framePosition.height * 0.5,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Frame 1\nContent Area',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              // Frame number label for first frame
              pw.Positioned(
                left: 5,
                bottom: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.orange,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    '1',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Second frame area (bottom half of page)
      pw.Positioned(
        left: 0,
        top: halfPageHeight,
        child: pw.Container(
          width: 432, // Full page width
          height: halfPageHeight,
          child: pw.Stack(
            children: [
              // White background for second frame
              pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
              // Test pattern for second frame content area
              pw.Positioned(
                left: framePosition.left,
                top: framePosition.top * 0.5,
                child: pw.Container(
                  width: framePosition.width,
                  height: framePosition.height * 0.5,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border.all(color: PdfColors.blue, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Frame 2\nContent Area',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              // Frame number label for second frame
              pw.Positioned(
                left: 5,
                bottom: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.orange,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    '2',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Add reference line to show page split
      pw.Positioned(
        left: 0,
        top: halfPageHeight - 1,
        child: pw.Container(
          width: 432, // Full page width
          height: 2,
          color: PdfColors.green,
        ),
      ),
      // Add corner markers for alignment reference
      ..._buildCornerMarkers(),
    ];
  }

  Future<Uint8List> _generateFlipbookFrameTestPdf() async {
    final pdf = pw.Document();

    // Use the first flipbook frame for testing
    const frameAssetPath = 'assets/flipbook/frame1.png';

    pw.MemoryImage? frameImage;
    try {
      final frameImageBytes = await rootBundle.load(frameAssetPath);
      frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());
    } catch (e) {
      print('Warning: Could not load flipbook frame asset: $e');
    }

    // DNP DS-RX1HS specific dimensions with bleed compensation
    const double bleedMm = 3.0;
    const double bleedPoints = bleedMm * 2.834645669;
    const double originalWidth = 4 * PdfPageFormat.inch;
    const double originalHeight = 6 * PdfPageFormat.inch;
    const double adjustedWidth = originalWidth + (bleedPoints * 2);
    const double adjustedHeight = originalHeight + (bleedPoints * 4);

    pdf.addPage(
      pw.Page(
        orientation: pw.PageOrientation.landscape,
        pageFormat: PdfPageFormat(adjustedWidth, adjustedHeight),
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          const double scaleFactor = 1.00;
          const double offsetX = bleedPoints * -1; // Reduced to move right
          const double offsetY = bleedPoints * 1.5; // Increased to move up

          return pw.Transform.scale(
            scale: scaleFactor,
            child: pw.Transform.translate(
              offset: const PdfPoint(-offsetX, -offsetY),
              child: pw.Stack(
                children: [
                  // Build test pattern with proper frame structure
                  ..._buildTestPatternForFlipbookFrame(),
                  // Frame overlay on top of first frame (top half)
                  if (frameImage != null)
                    pw.Positioned(
                      left: 0,
                      top: 0,
                      child: pw.Container(
                        width: 432,
                        height: 144, // Half page height
                        child: pw.Image(frameImage, fit: pw.BoxFit.fill),
                      ),
                    ),
                  // Frame overlay on top of second frame (bottom half)
                  if (frameImage != null)
                    pw.Positioned(
                      left: 0,
                      top: 144, // Start at half page height
                      child: pw.Container(
                        width: 432,
                        height: 144, // Half page height
                        child: pw.Image(frameImage, fit: pw.BoxFit.fill),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildCornerMarkers() {
    const markerSize = 10.0;
    const pageWidth = 432.0;
    const pageHeight = 288.0;

    return [
      // Top-left corner
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.Container(
          width: markerSize,
          height: markerSize,
          color: PdfColors.black,
        ),
      ),
      // Top-right corner
      pw.Positioned(
        left: pageWidth - markerSize,
        top: 0,
        child: pw.Container(
          width: markerSize,
          height: markerSize,
          color: PdfColors.black,
        ),
      ),
      // Bottom-left corner
      pw.Positioned(
        left: 0,
        top: pageHeight - markerSize,
        child: pw.Container(
          width: markerSize,
          height: markerSize,
          color: PdfColors.black,
        ),
      ),
      // Bottom-right corner
      pw.Positioned(
        left: pageWidth - markerSize,
        top: pageHeight - markerSize,
        child: pw.Container(
          width: markerSize,
          height: markerSize,
          color: PdfColors.black,
        ),
      ),
      // Center markers for half-page split
      pw.Positioned(
        left: 0,
        top: pageHeight / 2 - 5,
        child: pw.Container(width: 20, height: 10, color: PdfColors.orange),
      ),
      pw.Positioned(
        left: pageWidth - 20,
        top: pageHeight / 2 - 5,
        child: pw.Container(width: 20, height: 10, color: PdfColors.orange),
      ),
    ];
  }
}

final printerProvider = AsyncNotifierProvider<PrinterNotifier, PrinterState>(
  () => PrinterNotifier(),
);
