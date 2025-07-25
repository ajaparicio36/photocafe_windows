import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/base_frame_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/classic_frame_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/two_by_two_frame_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/four_by_four_frame_widget.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';

class FrameFactory {
  static Widget createFrameWidget(FrameDefinition frameDefinition) {
    switch (frameDefinition.previewWidgetName) {
      case 'ClassicFramePreview':
        return ClassicFrameWidget(frameDefinition: frameDefinition);
      case 'TwoByTwoFramePreview':
        return TwoByTwoFrameWidget(frameDefinition: frameDefinition);
      case 'FourByFourFramePreview':
        return FourByFourFrameWidget(frameDefinition: frameDefinition);
      default:
        return Container(
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
    FrameDefinition frameDefinition,
    List<PhotoModel> photos,
    int layoutMode, // Changed from captureCount to layoutMode
  ) async {
    final layoutType = layoutMode == 2
        ? FrameLayoutType.twoPhotos
        : FrameLayoutType.fourPhotos;
    final layout = frameDefinition.layouts[layoutType];

    if (layout == null) {
      throw Exception(
        'Layout not supported for frame: ${frameDefinition.name}',
      );
    }

    final tempWidget = _createTempWidget(frameDefinition);
    return await tempWidget.generatePdfFromLayout(photos, layoutMode, layout);
  }

  static BaseFrameWidget _createTempWidget(FrameDefinition frameDefinition) {
    switch (frameDefinition.previewWidgetName) {
      case 'ClassicFramePreview':
        return ClassicFrameWidget(frameDefinition: frameDefinition);
      case 'TwoByTwoFramePreview':
        return TwoByTwoFrameWidget(frameDefinition: frameDefinition);
      case 'FourByFourFramePreview':
        return FourByFourFrameWidget(frameDefinition: frameDefinition);
      default:
        return ClassicFrameWidget(frameDefinition: frameDefinition);
    }
  }
}
