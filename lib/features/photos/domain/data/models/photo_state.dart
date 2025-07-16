import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';

part 'photo_state.freezed.dart';
part 'photo_state.g.dart';

@freezed
sealed class PhotoState with _$PhotoState {
  const factory PhotoState({
    required List<PhotoModel> photos,
    required String tempPath,
    required int captureCount,
    String? error,
  }) = _PhotoState;

  factory PhotoState.fromJson(Map<String, dynamic> json) =>
      _$PhotoStateFromJson(json);
}
