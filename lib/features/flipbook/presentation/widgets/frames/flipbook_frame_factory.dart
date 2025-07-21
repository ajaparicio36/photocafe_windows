import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/base_flipbook_frame_widget.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/standard_flipbook_frame_widget.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/frame_model.dart';

class FlipbookFrameFactory {
  static Widget createFrameWidget(FlipbookFrameDefinition frameDefinition) {
    switch (frameDefinition.previewWidgetName) {
      case 'StandardFlipbookFrame':
        return StandardFlipbookFrameWidget(
          key: ValueKey('standard_frame_${frameDefinition.id}'),
          frameDefinition: frameDefinition,
        );
      default:
        return Container(
          key: ValueKey('unknown_frame_${frameDefinition.id}'),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Frame widget not found:\n${frameDefinition.previewWidgetName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
    }
  }

  static Future<Uint8List> generatePdfForFrame(
    FlipbookFrameDefinition frameDefinition,
    List<FrameModel> frames,
  ) async {
    // Create a temporary widget to use the base PDF generation
    final tempWidget = _createTempWidget(frameDefinition);
    return await tempWidget.generatePdfFromLayout(
      frames,
      frameDefinition.layout,
    );
  }

  static BaseFlipbookFrameWidget _createTempWidget(
    FlipbookFrameDefinition frameDefinition,
  ) {
    switch (frameDefinition.previewWidgetName) {
      case 'StandardFlipbookFrame':
        return StandardFlipbookFrameWidget(frameDefinition: frameDefinition);
      default:
        return StandardFlipbookFrameWidget(frameDefinition: frameDefinition);
    }
  }
}
