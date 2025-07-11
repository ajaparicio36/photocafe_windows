// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'printer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrinterState {

 String? get cutEnabledPrinter; String? get cutDisabledPrinter; String? get error;
/// Create a copy of PrinterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrinterStateCopyWith<PrinterState> get copyWith => _$PrinterStateCopyWithImpl<PrinterState>(this as PrinterState, _$identity);

  /// Serializes this PrinterState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrinterState&&(identical(other.cutEnabledPrinter, cutEnabledPrinter) || other.cutEnabledPrinter == cutEnabledPrinter)&&(identical(other.cutDisabledPrinter, cutDisabledPrinter) || other.cutDisabledPrinter == cutDisabledPrinter)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cutEnabledPrinter,cutDisabledPrinter,error);

@override
String toString() {
  return 'PrinterState(cutEnabledPrinter: $cutEnabledPrinter, cutDisabledPrinter: $cutDisabledPrinter, error: $error)';
}


}

/// @nodoc
abstract mixin class $PrinterStateCopyWith<$Res>  {
  factory $PrinterStateCopyWith(PrinterState value, $Res Function(PrinterState) _then) = _$PrinterStateCopyWithImpl;
@useResult
$Res call({
 String? cutEnabledPrinter, String? cutDisabledPrinter, String? error
});




}
/// @nodoc
class _$PrinterStateCopyWithImpl<$Res>
    implements $PrinterStateCopyWith<$Res> {
  _$PrinterStateCopyWithImpl(this._self, this._then);

  final PrinterState _self;
  final $Res Function(PrinterState) _then;

/// Create a copy of PrinterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cutEnabledPrinter = freezed,Object? cutDisabledPrinter = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
cutEnabledPrinter: freezed == cutEnabledPrinter ? _self.cutEnabledPrinter : cutEnabledPrinter // ignore: cast_nullable_to_non_nullable
as String?,cutDisabledPrinter: freezed == cutDisabledPrinter ? _self.cutDisabledPrinter : cutDisabledPrinter // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PrinterState implements PrinterState {
  const _PrinterState({this.cutEnabledPrinter, this.cutDisabledPrinter, this.error});
  factory _PrinterState.fromJson(Map<String, dynamic> json) => _$PrinterStateFromJson(json);

@override final  String? cutEnabledPrinter;
@override final  String? cutDisabledPrinter;
@override final  String? error;

/// Create a copy of PrinterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrinterStateCopyWith<_PrinterState> get copyWith => __$PrinterStateCopyWithImpl<_PrinterState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrinterStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrinterState&&(identical(other.cutEnabledPrinter, cutEnabledPrinter) || other.cutEnabledPrinter == cutEnabledPrinter)&&(identical(other.cutDisabledPrinter, cutDisabledPrinter) || other.cutDisabledPrinter == cutDisabledPrinter)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cutEnabledPrinter,cutDisabledPrinter,error);

@override
String toString() {
  return 'PrinterState(cutEnabledPrinter: $cutEnabledPrinter, cutDisabledPrinter: $cutDisabledPrinter, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PrinterStateCopyWith<$Res> implements $PrinterStateCopyWith<$Res> {
  factory _$PrinterStateCopyWith(_PrinterState value, $Res Function(_PrinterState) _then) = __$PrinterStateCopyWithImpl;
@override @useResult
$Res call({
 String? cutEnabledPrinter, String? cutDisabledPrinter, String? error
});




}
/// @nodoc
class __$PrinterStateCopyWithImpl<$Res>
    implements _$PrinterStateCopyWith<$Res> {
  __$PrinterStateCopyWithImpl(this._self, this._then);

  final _PrinterState _self;
  final $Res Function(_PrinterState) _then;

/// Create a copy of PrinterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cutEnabledPrinter = freezed,Object? cutDisabledPrinter = freezed,Object? error = freezed,}) {
  return _then(_PrinterState(
cutEnabledPrinter: freezed == cutEnabledPrinter ? _self.cutEnabledPrinter : cutEnabledPrinter // ignore: cast_nullable_to_non_nullable
as String?,cutDisabledPrinter: freezed == cutDisabledPrinter ? _self.cutDisabledPrinter : cutDisabledPrinter // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
