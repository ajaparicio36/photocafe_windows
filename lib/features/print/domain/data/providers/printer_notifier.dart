import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows_printer/windows_printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  Future<void> printPdfBytes(Uint8List pdfBytes, {bool cut = false}) async {
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
}

final printerProvider = AsyncNotifierProvider<PrinterNotifier, PrinterState>(
  () => PrinterNotifier(),
);
