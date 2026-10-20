import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
sealed class PhotoModel with _$PhotoModel {
  const factory PhotoModel({required String imagePath, required int index,
    @Default('') String captureId, String? originalPath}) =
      _PhotoModel;

  factory PhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoModelFromJson(json);
}
