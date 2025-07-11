// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoModel _$PhotoModelFromJson(Map<String, dynamic> json) => _PhotoModel(
  imagePath: json['imagePath'] as String,
  index: (json['index'] as num).toInt(),
);

Map<String, dynamic> _$PhotoModelToJson(_PhotoModel instance) =>
    <String, dynamic>{'imagePath': instance.imagePath, 'index': instance.index};
