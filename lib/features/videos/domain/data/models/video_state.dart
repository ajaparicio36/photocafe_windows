import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';

part 'video_state.freezed.dart';
part 'video_state.g.dart';

@freezed
sealed class VideoState with _$VideoState {
  const factory VideoState({
    String? videoPath,
    required List<FrameModel> frames,
    required String tempPath,
    String? error,
    @Default(false) bool isRecording,
  }) = _VideoState;

  factory VideoState.fromJson(Map<String, dynamic> json) =>
      _$VideoStateFromJson(json);
}
