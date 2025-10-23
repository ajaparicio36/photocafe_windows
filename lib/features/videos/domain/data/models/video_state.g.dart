// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoState _$VideoStateFromJson(Map<String, dynamic> json) => _VideoState(
  videoPath: json['videoPath'] as String?,
  videoTakes: (json['videoTakes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  selectedTakeIndex: (json['selectedTakeIndex'] as num?)?.toInt(),
  frames: (json['frames'] as List<dynamic>)
      .map((e) => FrameModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  tempPath: json['tempPath'] as String,
  error: json['error'] as String?,
  isRecording: json['isRecording'] as bool? ?? false,
);

Map<String, dynamic> _$VideoStateToJson(_VideoState instance) =>
    <String, dynamic>{
      'videoPath': instance.videoPath,
      'videoTakes': instance.videoTakes,
      'selectedTakeIndex': instance.selectedTakeIndex,
      'frames': instance.frames,
      'tempPath': instance.tempPath,
      'error': instance.error,
      'isRecording': instance.isRecording,
    };
