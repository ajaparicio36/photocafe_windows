// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoState {

 String? get videoPath; List<FrameModel> get frames; String get tempPath; String? get error; bool get isRecording;
/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoStateCopyWith<VideoState> get copyWith => _$VideoStateCopyWithImpl<VideoState>(this as VideoState, _$identity);

  /// Serializes this VideoState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoState&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.error, error) || other.error == error)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoPath,const DeepCollectionEquality().hash(frames),tempPath,error,isRecording);

@override
String toString() {
  return 'VideoState(videoPath: $videoPath, frames: $frames, tempPath: $tempPath, error: $error, isRecording: $isRecording)';
}


}

/// @nodoc
abstract mixin class $VideoStateCopyWith<$Res>  {
  factory $VideoStateCopyWith(VideoState value, $Res Function(VideoState) _then) = _$VideoStateCopyWithImpl;
@useResult
$Res call({
 String? videoPath, List<FrameModel> frames, String tempPath, String? error, bool isRecording
});




}
/// @nodoc
class _$VideoStateCopyWithImpl<$Res>
    implements $VideoStateCopyWith<$Res> {
  _$VideoStateCopyWithImpl(this._self, this._then);

  final VideoState _self;
  final $Res Function(VideoState) _then;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoPath = freezed,Object? frames = null,Object? tempPath = null,Object? error = freezed,Object? isRecording = null,}) {
  return _then(_self.copyWith(
videoPath: freezed == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<FrameModel>,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _VideoState implements VideoState {
  const _VideoState({this.videoPath, required final  List<FrameModel> frames, required this.tempPath, this.error, this.isRecording = false}): _frames = frames;
  factory _VideoState.fromJson(Map<String, dynamic> json) => _$VideoStateFromJson(json);

@override final  String? videoPath;
 final  List<FrameModel> _frames;
@override List<FrameModel> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override final  String tempPath;
@override final  String? error;
@override@JsonKey() final  bool isRecording;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoStateCopyWith<_VideoState> get copyWith => __$VideoStateCopyWithImpl<_VideoState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoState&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.error, error) || other.error == error)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoPath,const DeepCollectionEquality().hash(_frames),tempPath,error,isRecording);

@override
String toString() {
  return 'VideoState(videoPath: $videoPath, frames: $frames, tempPath: $tempPath, error: $error, isRecording: $isRecording)';
}


}

/// @nodoc
abstract mixin class _$VideoStateCopyWith<$Res> implements $VideoStateCopyWith<$Res> {
  factory _$VideoStateCopyWith(_VideoState value, $Res Function(_VideoState) _then) = __$VideoStateCopyWithImpl;
@override @useResult
$Res call({
 String? videoPath, List<FrameModel> frames, String tempPath, String? error, bool isRecording
});




}
/// @nodoc
class __$VideoStateCopyWithImpl<$Res>
    implements _$VideoStateCopyWith<$Res> {
  __$VideoStateCopyWithImpl(this._self, this._then);

  final _VideoState _self;
  final $Res Function(_VideoState) _then;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoPath = freezed,Object? frames = null,Object? tempPath = null,Object? error = freezed,Object? isRecording = null,}) {
  return _then(_VideoState(
videoPath: freezed == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<FrameModel>,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
