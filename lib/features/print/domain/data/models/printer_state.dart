import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_state.freezed.dart';
part 'printer_state.g.dart';

@freezed
sealed class PrinterState with _$PrinterState {
  const factory PrinterState({
    String? cutEnabledPrinter,
    String? cutDisabledPrinter,
    String? error,
  }) = _PrinterState;

  factory PrinterState.fromJson(Map<String, dynamic> json) =>
      _$PrinterStateFromJson(json);
}
