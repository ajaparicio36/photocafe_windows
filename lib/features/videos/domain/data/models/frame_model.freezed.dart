// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FrameModel {

 String get path; int get index; bool get isSelected;
/// Create a copy of FrameModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrameModelCopyWith<FrameModel> get copyWith => _$FrameModelCopyWithImpl<FrameModel>(this as FrameModel, _$identity);

  /// Serializes this FrameModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrameModel&&(identical(other.path, path) || other.path == path)&&(identical(other.index, index) || other.index == index)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,index,isSelected);

@override
String toString() {
  return 'FrameModel(path: $path, index: $index, isSelected: $isSelected)';
}


}

/// @nodoc
abstract mixin class $FrameModelCopyWith<$Res>  {
  factory $FrameModelCopyWith(FrameModel value, $Res Function(FrameModel) _then) = _$FrameModelCopyWithImpl;
@useResult
$Res call({
 String path, int index, bool isSelected
});




}
/// @nodoc
class _$FrameModelCopyWithImpl<$Res>
    implements $FrameModelCopyWith<$Res> {
  _$FrameModelCopyWithImpl(this._self, this._then);

  final FrameModel _self;
  final $Res Function(FrameModel) _then;

/// Create a copy of FrameModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? index = null,Object? isSelected = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FrameModel implements FrameModel {
  const _FrameModel({required this.path, required this.index, this.isSelected = false});
  factory _FrameModel.fromJson(Map<String, dynamic> json) => _$FrameModelFromJson(json);

@override final  String path;
@override final  int index;
@override@JsonKey() final  bool isSelected;

/// Create a copy of FrameModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrameModelCopyWith<_FrameModel> get copyWith => __$FrameModelCopyWithImpl<_FrameModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FrameModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FrameModel&&(identical(other.path, path) || other.path == path)&&(identical(other.index, index) || other.index == index)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,index,isSelected);

@override
String toString() {
  return 'FrameModel(path: $path, index: $index, isSelected: $isSelected)';
}


}

/// @nodoc
abstract mixin class _$FrameModelCopyWith<$Res> implements $FrameModelCopyWith<$Res> {
  factory _$FrameModelCopyWith(_FrameModel value, $Res Function(_FrameModel) _then) = __$FrameModelCopyWithImpl;
@override @useResult
$Res call({
 String path, int index, bool isSelected
});




}
/// @nodoc
class __$FrameModelCopyWithImpl<$Res>
    implements _$FrameModelCopyWith<$Res> {
  __$FrameModelCopyWithImpl(this._self, this._then);

  final _FrameModel _self;
  final $Res Function(_FrameModel) _then;

/// Create a copy of FrameModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? index = null,Object? isSelected = null,}) {
  return _then(_FrameModel(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
