import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/base_flipbook_frame_widget.dart';

class FlipbookFrameOne extends BaseFlipbookFrameWidget {
  const FlipbookFrameOne({super.key})
    : super(frameDefinition: FlipbookFrameConstants.standardFrame);

  // Static method to allow calling from outside the widget (backward compatibility)
  static Future<Uint8List> generatePdfStatic(List<FrameModel> frames) async {
    const frameDefinition = FlipbookFrameConstants.standardFrame;
    final tempWidget = FlipbookFrameOne();
    return await tempWidget.generatePdfFromLayout(
      frames,
      frameDefinition.layout,
    );
  }

  @override
  Future<Uint8List> generatePdf(
    List<FrameModel> frames,
    FlipbookFrameLayout layout,
  ) async {
    // Use the base implementation for standard PDF generation
    return await generatePdfFromLayout(frames, layout);
  }
}
