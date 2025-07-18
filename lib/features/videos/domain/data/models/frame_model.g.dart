// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FrameModel _$FrameModelFromJson(Map<String, dynamic> json) => _FrameModel(
  path: json['path'] as String,
  index: (json['index'] as num).toInt(),
  isSelected: json['isSelected'] as bool? ?? false,
);

Map<String, dynamic> _$FrameModelToJson(_FrameModel instance) =>
    <String, dynamic>{
      'path': instance.path,
      'index': instance.index,
      'isSelected': instance.isSelected,
    };
