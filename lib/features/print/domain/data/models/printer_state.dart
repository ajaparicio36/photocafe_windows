import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_state.freezed.dart';
part 'printer_state.g.dart';

@freezed
sealed class PrinterState with _$PrinterState {
  const factory PrinterState({
    String? cutEnabledPrinter,
    String? cutDisabledPrinter,
    String? videoPrinter,
    String? photoCameraName,
    String? videoCameraName,
    @Default(2) int layoutMode, // 2 for 2x2 layout, 4 for 4x4 layout
    @Default(false) bool isFullscreen, // Add fullscreen mode setting
    String? error,
  }) = _PrinterState;

  factory PrinterState.fromJson(Map<String, dynamic> json) =>
      _$PrinterStateFromJson(json);
}
