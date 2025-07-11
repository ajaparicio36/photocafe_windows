// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoState {

 List<PhotoModel> get photos; String get tempPath; String? get error;
/// Create a copy of PhotoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoStateCopyWith<PhotoState> get copyWith => _$PhotoStateCopyWithImpl<PhotoState>(this as PhotoState, _$identity);

  /// Serializes this PhotoState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoState&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(photos),tempPath,error);

@override
String toString() {
  return 'PhotoState(photos: $photos, tempPath: $tempPath, error: $error)';
}


}

/// @nodoc
abstract mixin class $PhotoStateCopyWith<$Res>  {
  factory $PhotoStateCopyWith(PhotoState value, $Res Function(PhotoState) _then) = _$PhotoStateCopyWithImpl;
@useResult
$Res call({
 List<PhotoModel> photos, String tempPath, String? error
});




}
/// @nodoc
class _$PhotoStateCopyWithImpl<$Res>
    implements $PhotoStateCopyWith<$Res> {
  _$PhotoStateCopyWithImpl(this._self, this._then);

  final PhotoState _self;
  final $Res Function(PhotoState) _then;

/// Create a copy of PhotoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photos = null,Object? tempPath = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<PhotoModel>,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PhotoState implements PhotoState {
  const _PhotoState({required final  List<PhotoModel> photos, required this.tempPath, this.error}): _photos = photos;
  factory _PhotoState.fromJson(Map<String, dynamic> json) => _$PhotoStateFromJson(json);

 final  List<PhotoModel> _photos;
@override List<PhotoModel> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  String tempPath;
@override final  String? error;

/// Create a copy of PhotoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoStateCopyWith<_PhotoState> get copyWith => __$PhotoStateCopyWithImpl<_PhotoState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoState&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_photos),tempPath,error);

@override
String toString() {
  return 'PhotoState(photos: $photos, tempPath: $tempPath, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PhotoStateCopyWith<$Res> implements $PhotoStateCopyWith<$Res> {
  factory _$PhotoStateCopyWith(_PhotoState value, $Res Function(_PhotoState) _then) = __$PhotoStateCopyWithImpl;
@override @useResult
$Res call({
 List<PhotoModel> photos, String tempPath, String? error
});




}
/// @nodoc
class __$PhotoStateCopyWithImpl<$Res>
    implements _$PhotoStateCopyWith<$Res> {
  __$PhotoStateCopyWithImpl(this._self, this._then);

  final _PhotoState _self;
  final $Res Function(_PhotoState) _then;

/// Create a copy of PhotoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photos = null,Object? tempPath = null,Object? error = freezed,}) {
  return _then(_PhotoState(
photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<PhotoModel>,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
