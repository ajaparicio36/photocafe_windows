import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame_model.freezed.dart';
part 'frame_model.g.dart';

@freezed
sealed class FrameModel with _$FrameModel {
  const factory FrameModel({
    required String path,
    required int index,
    @Default(false) bool isSelected,
  }) = _FrameModel;

  factory FrameModel.fromJson(Map<String, dynamic> json) =>
      _$FrameModelFromJson(json);
}
