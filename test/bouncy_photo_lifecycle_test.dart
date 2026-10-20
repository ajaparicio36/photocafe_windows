import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late Uint8List jpeg;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bouncy_photos_test_');
    jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 64, height: 36)));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    container = ProviderContainer(
      overrides: [photoProvider.overrideWith(() => _Photos(directory.path))],
    );
    await container.read(photoProvider.future);
  });
  tearDown(() async {
    final state = container.read(photoProvider).value;
    container.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
    if (state != null &&
        state.tempPath != directory.path &&
        await Directory(state.tempPath).exists()) {
      await Directory(state.tempPath).delete(recursive: true);
    }
  });
  BouncyClip clip() => validateBouncyImages(
    BouncyClip([
      for (var i = 0; i <= 30; i++) BouncyFrame(i * 100000, jpeg),
    ], 3000000),
  );
  test(
    'retake commits only selected identity and missing replacement leaves pair registry unchanged',
    () async {
      final source = File('${directory.path}/fixture.jpg');
      await source.writeAsBytes(jpeg);
      final notifier = container.read(photoProvider.notifier);
      final session = container.read(bouncySessionProvider);
      for (var i = 0; i < 4; i++) {
        await notifier.addPhotoFromFile(
          source.path,
          attempt: session.attempt('shot$i'),
          clip: clip(),
        );
      }
      final before = container.read(photoProvider).requireValue.photos;
      final preserved = session.clip('shot1');
      final invalid = BouncyAttempt(session.generation, 999, 'missing');
      await expectLater(
        notifier.addPhotoFromFile(
          source.path,
          attempt: invalid,
          clip: clip(),
          replaceIndex: 99,
        ),
        throwsStateError,
      );
      expect(session.clip('missing'), isNull);
      await notifier.addPhotoFromFile(
        source.path,
        attempt: session.attempt('shot0'),
        clip: clip(),
        replaceIndex: 0,
      );
      final after = container.read(photoProvider).requireValue.photos;
      expect(after[0].captureId, 'shot0');
      expect(after[0].imagePath, isNot(before[0].imagePath));
      expect(after.sublist(1), before.sublist(1));
      expect(session.clip('shot1'), same(preserved));
      await notifier.reorderPhotos(after.reversed.toList());
      expect(
        container
            .read(photoProvider)
            .requireValue
            .photos
            .map((p) => p.captureId),
        ['shot3', 'shot2', 'shot1', 'shot0'],
      );
      expect(session.valid(after.map((p) => p.captureId)), isTrue);
      final reordered = container.read(photoProvider).requireValue.photos;
      final target = reordered.first;
      final otherClips = [
        for (final p in reordered.skip(1)) session.clip(p.captureId),
      ];
      await notifier.addPhotoFromFile(
        source.path,
        attempt: session.attempt(target.captureId),
        clip: clip(),
        replaceIndex: target.index,
      );
      expect(
        container.read(photoProvider).requireValue.photos.skip(1),
        reordered.skip(1),
      );
      expect([
        for (final p in reordered.skip(1)) session.clip(p.captureId),
      ], otherClips);
    },
  );
  test(
    'repeated reset coalesces; pending filter cannot republish old photos or retain owned directory',
    () async {
      final source = File('${directory.path}/fixture.jpg');
      await source.writeAsBytes(jpeg);
      final notifier = container.read(photoProvider.notifier);
      await notifier.addPhotoFromFile(source.path);
      final filtering = notifier.applyFilters(_slowFilter);
      final reset = notifier.clearAllPhotos();
      expect(notifier.clearAllPhotos(), same(reset));
      await Future.wait([filtering, reset]);
      expect(container.read(photoProvider).requireValue.photos, isEmpty);
      expect(await directory.exists(), isFalse);
    },
  );
  test(
    'PDF raster save is drained and cannot publish its path after reset',
    () async {
      container.dispose();
      final raster = Completer<Uint8List>();
      container = ProviderContainer(
        overrides: [
          photoProvider.overrideWith(
            () => _Photos(directory.path, raster: raster),
          ),
        ],
      );
      await container.read(photoProvider.future);
      final notifier = container.read(photoProvider.notifier);
      final save = notifier.saveFramePdf(Uint8List.fromList([1, 2]));
      final failedSave = expectLater(save, throwsStateError);
      final reset = notifier.clearAllPhotos();
      raster.complete(
        Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2))),
      );
      await failedSave;
      await reset;
      expect(notifier.savedFramePdfPath, isNull);
      expect(await directory.exists(), isFalse);
    },
  );
}

img.Image _slowFilter(img.Image source) {
  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < 150) {
    /* deterministic in-flight work */
  }
  return source;
}

class _Photos extends PhotoNotifier {
  final String _directory;
  final Completer<Uint8List>? _raster;
  _Photos(this._directory, {Completer<Uint8List>? raster}) : _raster = raster;
  @override
  Future<Uint8List> rasterFrame(Uint8List pdfBytes) =>
      _raster?.future ?? super.rasterFrame(pdfBytes);
  @override
  Future<PhotoState> build() async => PhotoState(
    photos: const <PhotoModel>[],
    tempPath: _directory,
    captureCount: 4,
  );
}
