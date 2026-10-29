import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  BouncySession session() {
    final result = BouncySession();
    for (var shot = 0; shot < 4; shot++) {
      final frames = <BouncyFrame>[];
      for (var i = 0; i <= 30; i++) {
        final image = img.Image(width: 64, height: 36);
        img.fill(image, color: img.ColorRgb8(shot * 60, i * 7, 100));
        frames.add(
          BouncyFrame(i * 100000, Uint8List.fromList(img.encodeJpg(image))),
        );
      }
      result.accept(
        result.attempt('shot$shot'),
        validateBouncyImages(BouncyClip(frames, 3000000)),
      );
    }
    return result;
  }

  final photos = [
    for (var i = 0; i < 4; i++)
      PhotoModel(imagePath: '', index: i, captureId: 'shot$i'),
  ];

  test(
    'preview decode working dimensions bound the longest side and never upscale',
    () {
      expect(bouncyPreviewDimensions(16, 129600), (width: 1, height: 320));
      expect(bouncyPreviewDimensions(1920, 1080), (width: 320, height: 180));
      expect(bouncyPreviewDimensions(1080, 1920), (width: 180, height: 320));
      expect(bouncyPreviewDimensions(64, 36), (width: 64, height: 36));
    },
  );
  test(
    'whole four-design preview and higher-quality MP4; silent six-second output, failure keeps print gate',
    () async {
      final captures = session();
      final media = BouncyMediaService(
        captures,
        encoders: ['unavailable_codec', 'libx264'],
      );
      final selection = KeychainSessionState.initial().variants;
      final frames = await media.prepare(photos: photos, selections: selection);
      expect(frames.length, 36);
      expect(frames.first, frames.last);
      expect(frames[17], frames[18]);
      final decoded = img.decodePng(frames.first)!;
      expect((decoded.width, decoded.height), (620, 922));
      expect(frames.first, isNot(frames[17]));
      media.failEncoder = true;
      await expectLater(media.export(), throwsStateError);
      expect(captures.valid(photos.map((p) => p.captureId)), isTrue);
      media.failEncoder = false;
      final path = await media.export();
      expect(await File(path).length(), greaterThan(1024));
      expect(media.encoder, 'libx264');
      final evidence = await Directory.systemTemp.createTemp(
        'bouncy_app_proof_',
      );
      await File(path).copy('${evidence.path}/bouncy_preview.mp4');
      // Private generated fixture only; its path is useful to local archive QA.
      // ignore: avoid_print
      print(
        'BOUNCY_FIXTURE_MP4=${evidence.path}/bouncy_preview.mp4; encoder=${media.encoder}',
      );
      await captures.drain();
      captures.reset();
      captures.setMotionEnabled(false);
      // OFF must reject a previously cached successful export immediately.
      await expectLater(media.export(), throwsStateError);
      await expectLater(
        media.prepare(photos: photos, selections: selection),
        throwsStateError,
      );
      expect(captures.hasWork, isFalse);
      await media.cancelAndDrain();
      expect(await File(path).exists(), isFalse);
      media.dispose();
      captures.dispose();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'soft-copy render preserves more source detail than enlarging preview',
    () async {
      final source = img.Image(width: 620, height: 922);
      for (final pixel in source) {
        final value = (pixel.x ~/ 2).isEven ? 0 : 255;
        pixel.setRgb(value, value, value);
      }
      final clip = validateBouncyImages(
        BouncyClip([
          BouncyFrame(
            3000000,
            Uint8List.fromList(img.encodeJpg(source, quality: 100)),
          ),
        ], 3000000),
      );
      final design = BouncyDesign(
        FrameLayout(
          type: FrameLayoutType.fourPhotos,
          leftColumnPositions: [
            FramePhotoPosition(
              left: 0,
              top: 0,
              width: FramePdfGeometry.pageWidth,
              height: FramePdfGeometry.pageHeight,
              photoIndex: 0,
            ),
          ],
          rightColumnPositions: const [],
          topOffset: 0,
          frameAssetPath: '',
        ),
        Uint8List.fromList(
          img.encodePng(img.Image(width: 2, height: 2, numChannels: 4)),
        ),
        'no_filter',
      );
      final preview = await renderBouncyCycle([clip], [design]);
      final output = await renderBouncyCycle(
        [clip],
        [design],
        quality: BouncyRenderQuality.softCopy,
      );
      final low = img.decodePng(preview.first)!;
      final high = img.decodePng(output.first)!;
      expect((low.width, low.height), (310, 462));
      expect((high.width, high.height), (620, 922));
      expect(output.length, 36);
      expect(output.first, output.last);
      final enlarged = img.copyResize(low, width: 620, height: 922);
      int edges(img.Image image) {
        var count = 0;
        for (var x = 1; x < image.width; x++) {
          if ((image.getPixel(x - 1, 450).r > 127) !=
              (image.getPixel(x, 450).r > 127)) {
            count++;
          }
        }
        return count;
      }

      expect(edges(high), greaterThan(edges(enlarged)));
      expect(bouncyWorkingDimensions(1920, 1080, maxSide: 640), (
        width: 640,
        height: 360,
      ));
      expect(bouncyWorkingDimensions(64, 36, maxSide: 640), (
        width: 64,
        height: 36,
      ));
      expect(bouncyEncoderQualityArguments('h264_nvenc'), [
        '-rc',
        'vbr',
        '-cq',
        '21',
        '-b:v',
        '0',
      ]);
      expect(bouncyEncoderQualityArguments('h264_qsv'), [
        '-global_quality',
        '21',
      ]);
      expect(bouncyEncoderQualityArguments('libx264'), [
        '-preset',
        'veryfast',
        '-crf',
        '21',
      ]);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'cancellation fences a late render without invalidating another session',
    () async {
      final captures = session();
      final media = BouncyMediaService(captures);
      final pending = media.prepare(
        photos: photos,
        selections: KeychainSessionState.initial().variants,
      );
      captures.reset();
      await expectLater(pending, throwsStateError);
      await captures.drain();
      await media.cancelAndDrain();
      expect(captures.pairCount, 0);
      media.dispose();
      captures.dispose();
    },
  );
}
