// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoState _$PhotoStateFromJson(Map<String, dynamic> json) => _PhotoState(
  photos: (json['photos'] as List<dynamic>)
      .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  tempPath: json['tempPath'] as String,
  captureCount: (json['captureCount'] as num).toInt(),
  error: json['error'] as String?,
  videoPath: json['videoPath'] as String?,
  isRecording: json['isRecording'] as bool? ?? false,
);

Map<String, dynamic> _$PhotoStateToJson(_PhotoState instance) =>
    <String, dynamic>{
      'photos': instance.photos,
      'tempPath': instance.tempPath,
      'captureCount': instance.captureCount,
      'error': instance.error,
      'videoPath': instance.videoPath,
      'isRecording': instance.isRecording,
    };
