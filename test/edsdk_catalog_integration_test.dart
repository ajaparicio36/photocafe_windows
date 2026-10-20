import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';

void main() {
  test('edsdk retains Portrait, Photobox and Landscape frame compositions', () {
    final counts = <FrameLayoutType, int>{};
    final photo = img.Image(width: 64, height: 48);
    img.fill(photo, color: img.ColorRgb8(60, 100, 180));
    final artwork = img.Image(width: 310, height: 461, numChannels: 4);
    for (final frame in FrameConstants.availableFrames) {
      for (final layout in frame.layouts.values) {
        expect(
          File(layout.frameAssetPath).existsSync(),
          isTrue,
          reason: '${frame.id} must retain its shipped artwork',
        );
        counts.update(layout.type, (value) => value + 1, ifAbsent: () => 1);
        final raster = FrameCompositionRenderer.renderDecodedVariant(
          layout: layout,
          frame: artwork,
          photos: [photo, photo, photo, photo],
          width: 310,
          height: 461,
        );
        expect(
          (raster.width, raster.height),
          (310, 461),
          reason: '${frame.id} must remain renderable',
        );
      }
    }
    expect(counts, {
      FrameLayoutType.fourPhotos: 12,
      FrameLayoutType.twoPhotos: 7,
      FrameLayoutType.fourLandscapePhotos: 6,
    });
  });
}
