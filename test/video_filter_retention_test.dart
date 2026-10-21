import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/videos/domain/data/constants/filter_constants.dart';
import 'package:photocafe_windows/features/videos/domain/data/models/video_state.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class _TestVideoNotifier extends VideoNotifier {
  _TestVideoNotifier(this._initialState);

  final VideoState _initialState;

  @override
  Future<VideoState> build() async => _initialState;
}

void main() {
  for (final imported in [false, true]) {
    test(
      'filtering retains the ${imported ? 'imported video' : 'selected take'} for reselect and unfiltered frames',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'video_filter_test_',
        );
        addTearDown(() => root.delete(recursive: true));
        final source = File(p.join(root.path, 'take.mp4'));
        final generated = await Process.run('ffmpeg', [
          '-v',
          'error',
          '-f',
          'lavfi',
          '-i',
          'testsrc2=size=160x90:rate=10:duration=7',
          '-c:v',
          'libx264',
          '-pix_fmt',
          'yuv420p',
          source.path,
        ]);
        expect(generated.exitCode, 0, reason: '${generated.stderr}');
        final originalBytes = await source.readAsBytes();
        final notifier = _TestVideoNotifier(
          VideoState(
            videoPath: imported ? null : source.path,
            videoTakes: imported ? [] : [source.path],
            selectedTakeIndex: imported ? null : 0,
            frames: [],
            tempPath: root.path,
          ),
        );
        final container = ProviderContainer(
          overrides: [videoProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(videoProvider.future);
        if (imported) await notifier.loadExternalVideo(source.path);

        await notifier.processVideoWithFilter(
          VideoFilterConstants.blackAndWhiteFilterName,
        );
        final filtered = container.read(videoProvider).requireValue;
        expect(filtered.videoPath, isNot(source.path));
        expect(filtered.frames, hasLength(50));
        expect(filtered.videoTakes, [source.path]);
        expect(
          await source.exists(),
          isTrue,
          reason: 'Back to takes must still have the accepted original',
        );
        expect(await source.readAsBytes(), originalBytes);

        // The Back -> takes -> reselect -> No Filter path uses these same methods.
        await notifier.selectTake(0);
        await notifier.splitVideoIntoFrames();
        final unfiltered = container.read(videoProvider).requireValue;
        expect(unfiltered.videoPath, source.path);
        expect(unfiltered.frames, hasLength(50));
        expect(await source.readAsBytes(), originalBytes);

        // Existing explicit session cleanup still removes owned derivatives.
        final derivative = File(filtered.videoPath!);
        expect(await derivative.exists(), isTrue);
        await notifier.clearVideo();
        expect(await derivative.exists(), isFalse);
        expect(container.read(videoProvider).requireValue.videoTakes, isEmpty);
      },
    );
  }

  test('only owned unreferenced filter derivatives are replaced', () async {
    final root = await Directory.systemTemp.createTemp('video_filter_test_');
    addTearDown(() => root.delete(recursive: true));
    // A filter-like name inside temp is not proof that this notifier owns it.
    final source = File(p.join(root.path, 'filtered_imported.mp4'));
    final generated = await Process.run('ffmpeg', [
      '-v',
      'error',
      '-f',
      'lavfi',
      '-i',
      'testsrc2=size=160x90:rate=10:duration=1',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      source.path,
    ]);
    expect(generated.exitCode, 0, reason: '${generated.stderr}');
    final originalBytes = await source.readAsBytes();
    final notifier = _TestVideoNotifier(
      VideoState(
        videoPath: source.path,
        videoTakes: [],
        frames: [],
        tempPath: root.path,
      ),
    );
    final container = ProviderContainer(
      overrides: [videoProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    await container.read(videoProvider.future);

    final first = await notifier.applyVideoFilter(
      VideoFilterConstants.blackAndWhiteFilterName,
    );
    expect(first, isNotNull);
    expect(await source.readAsBytes(), originalBytes);
    expect(await File(first!).exists(), isTrue);

    final second = await notifier.applyVideoFilter(
      VideoFilterConstants.brightnessFilterName,
    );
    expect(second, isNotNull);
    expect(await File(second!).exists(), isTrue);
    expect(await File(first).exists(), isFalse);
    expect(await source.readAsBytes(), originalBytes);

    // Even an owned derivative becomes protected when imported as a take.
    await notifier.loadExternalVideo(second);
    await notifier.applyVideoFilter(VideoFilterConstants.contrastFilterName);
    expect(await File(second).exists(), isTrue);
    expect(container.read(videoProvider).requireValue.videoTakes, [second]);
  });
}
