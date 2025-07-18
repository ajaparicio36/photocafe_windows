import 'dart:typed_data';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/base_frame_widget.dart';

class VintageFrameWidget extends BaseFrameWidget {
  const VintageFrameWidget({super.key, required super.frameDefinition});

  @override
  Future<Uint8List> generatePdf(
    List<PhotoModel> photos,
    int captureCount,
    FrameLayout layout,
  ) async {
    // Custom implementation for vintage frame if needed
    // Or use the base implementation
    return await generatePdfFromLayout(photos, captureCount, layout);
  }
}
