import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';

void main() {
  test('sample-first filters preserve full-source crop, rotation, alpha and source-coordinate vignette', () {
    final sources = [for (var shot = 0; shot < 4; shot++) img.Image(width: 79 + shot * 2, height: 53 + shot * 4, numChannels: 4)];
    for (var i = 0; i < sources.length; i++) {
      for (final pixel in sources[i]) {
        pixel.setRgba((pixel.x * 17 + i * 31) % 256, pixel.y * 19 % 256,
          (pixel.x + pixel.y) * 7 % 256, 255);
      }
    }
    final frame = img.Image(width: 31, height: 47, numChannels: 4);
    img.fill(frame, color: img.ColorRgba8(200, 30, 80, 20));
    for (final type in FrameLayoutType.values) {
      final layout = FrameLayout(type: type, topOffset: 0, frameAssetPath: '',
        leftColumnPositions: const [
          FramePhotoPosition(left: 2.7, top: 3.1, width: 138.2, height: 190.7, rotationDegrees: 17),
          FramePhotoPosition(left: 3.9, top: 208.3, width: 134.1, height: 211.3, rotationDegrees: -23),
        ], rightColumnPositions: const [
          FramePhotoPosition(left: 150.9, top: 2.3, width: 138.3, height: 190.7, rotationDegrees: 90),
          FramePhotoPosition(left: 151.7, top: 209.1, width: 134.1, height: 211.3),
        ]);
      for (final filter in FilterConstants.filterDefinitions) {
        final reference = FrameCompositionRenderer.renderDecodedVariant(layout: layout,
          frame: frame, photos: [for (final source in sources) filter.applyFilter(img.Image.from(source))]);
        final actual = FrameCompositionRenderer.renderDecodedVariant(layout: layout,
          frame: frame, photos: sources, filterId: filter.id);
        expect(Uint8List.fromList(actual.getBytes()), reference.getBytes(), reason: '${type.name}/${filter.id}');
      }
    }
  });
}
