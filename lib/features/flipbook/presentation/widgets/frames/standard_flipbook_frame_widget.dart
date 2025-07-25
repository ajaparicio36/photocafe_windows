import 'dart:typed_data';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/base_flipbook_frame_widget.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';

class StandardFlipbookFrameWidget extends BaseFlipbookFrameWidget {
  const StandardFlipbookFrameWidget({
    super.key,
    required super.frameDefinition,
  });

  @override
  Future<Uint8List> generatePdf(
    List<FrameModel> frames,
    FlipbookFrameLayout layout,
  ) async {
    return await generatePdfFromLayout(frames, layout);
  }
}
