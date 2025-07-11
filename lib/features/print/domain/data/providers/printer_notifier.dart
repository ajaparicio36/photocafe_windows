import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows_printer/windows_printer.dart';

class PrinterNotifier extends AsyncNotifier<PrinterState> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<PrinterState> build() async {
    final availablePrinters = await getAvailablePrinters();
    final prefs = await _prefs;
    final cutEnabledPrinter = prefs.getString('cutEnabledPrinter');
    final cutDisabledPrinter = prefs.getString('cutDisabledPrinter');

    return PrinterState(
      cutEnabledPrinter: availablePrinters.contains(cutEnabledPrinter)
          ? cutEnabledPrinter
          : null,
      cutDisabledPrinter: availablePrinters.contains(cutDisabledPrinter)
          ? cutDisabledPrinter
          : null,
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

  Future<void> printPdfBytes(Uint8List pdfBytes, {bool cut = false}) async {
    final printerName = cut
        ? state.value?.cutEnabledPrinter
        : state.value?.cutDisabledPrinter;

    if (printerName == null || printerName.isEmpty) {
      throw Exception('No printer selected');
    }

    try {
      await WindowsPrinter.printPdf(data: pdfBytes, printerName: printerName);
    } catch (e) {
      throw Exception('Failed to print: ${e.toString()}');
    }
  }
}
