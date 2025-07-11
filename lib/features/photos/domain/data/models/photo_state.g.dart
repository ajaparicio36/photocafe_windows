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
  error: json['error'] as String?,
);

Map<String, dynamic> _$PhotoStateToJson(_PhotoState instance) =>
    <String, dynamic>{
      'photos': instance.photos,
      'tempPath': instance.tempPath,
      'error': instance.error,
    };
