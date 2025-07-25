// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PrinterState _$PrinterStateFromJson(Map<String, dynamic> json) =>
    _PrinterState(
      cutEnabledPrinter: json['cutEnabledPrinter'] as String?,
      cutDisabledPrinter: json['cutDisabledPrinter'] as String?,
      videoPrinter: json['videoPrinter'] as String?,
      photoCameraName: json['photoCameraName'] as String?,
      videoCameraName: json['videoCameraName'] as String?,
      layoutMode: (json['layoutMode'] as num?)?.toInt() ?? 2,
      isFullscreen: json['isFullscreen'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PrinterStateToJson(_PrinterState instance) =>
    <String, dynamic>{
      'cutEnabledPrinter': instance.cutEnabledPrinter,
      'cutDisabledPrinter': instance.cutDisabledPrinter,
      'videoPrinter': instance.videoPrinter,
      'photoCameraName': instance.photoCameraName,
      'videoCameraName': instance.videoCameraName,
      'layoutMode': instance.layoutMode,
      'isFullscreen': instance.isFullscreen,
      'error': instance.error,
    };
