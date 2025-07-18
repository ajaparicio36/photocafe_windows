import 'dart:typed_data';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/base_frame_widget.dart';

class FourByFourFrameWidget extends BaseFrameWidget {
  const FourByFourFrameWidget({super.key, required super.frameDefinition});

  @override
  Future<Uint8List> generatePdf(
    List<PhotoModel> photos,
    int captureCount,
    FrameLayout layout,
  ) async {
    // Use the base implementation for standard PDF generation
    return await generatePdfFromLayout(photos, captureCount, layout);
  }
}
