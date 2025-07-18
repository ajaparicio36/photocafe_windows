import 'dart:typed_data';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/base_flipbook_frame_widget.dart';

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
    // Use the base implementation for standard PDF generation
    return await generatePdfFromLayout(frames, layout);
  }
}
