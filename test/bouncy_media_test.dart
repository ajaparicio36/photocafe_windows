import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

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
    'whole four-design cycle and MP4 share frames; silent six-second output, failure keeps print gate',
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
      await media.cancelAndDrain();
      expect(await File(path).exists(), isFalse);
      media.dispose();
      captures.dispose();
    },
    timeout: const Timeout(Duration(minutes: 4)),
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
