import 'package:photocafe_windows/features/frame_catalog/domain/frame_artwork_loader.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

class BouncyDesign {
  final FrameLayout layout;
  final Uint8List artwork;
  final String filterId;
  const BouncyDesign(this.layout, this.artwork, this.filterId);
}

enum BouncyRenderQuality { preview, softCopy }

/// Preview and soft copies share the compositor, with separate raster budgets.
/// Still/PDF generation never consumes these reduced-resolution frames.
class BouncyMediaService {
  final BouncySession session;
  Future<List<Uint8List>>? _frames;
  Future<List<Uint8List>>? _preparation;
  Future<String>? _export;
  ({List<BouncyClip> clips, List<BouncyDesign> designs})? _exportInput;
  Future<void> _drain = Future.value();
  final Set<Directory> _directories = {};
  Process? _process;
  int _revision = 0;
  bool failEncoder = false;
  String? encoder;
  final List<String> encoders;
  BouncyMediaService(
    this.session, {
    this.encoders = const ['h264_nvenc', 'h264_qsv', 'libx264'],
  }) {
    session.cancellations.add(_cancelProcess);
  }
  void _cancelProcess() {
    _revision++;
    _process?.kill();
  }

  void dispose() {
    session.cancellations.remove(_cancelProcess);
    unawaited(cancelAndDrain());
  }

  Future<List<Uint8List>> prepare({
    required List<PhotoModel> photos,
    required List<KeychainVariantSelection> selections,
    FrameLayoutType? classicLayout,
  }) => _preparation = _prepare(
    photos: photos,
    selections: selections,
    classicLayout: classicLayout,
  );

  Future<List<Uint8List>> _prepare({
    required List<PhotoModel> photos,
    required List<KeychainVariantSelection> selections,
    FrameLayoutType? classicLayout,
  }) async {
    if (!session.motionEnabled) {
      throw StateError('Bouncy previews are off for this session.');
    }
    final revision = ++_revision;
    final generation = session.generation;
    _process?.kill();
    try {
      await _export;
    } catch (_) {}
    await _drain;
    _check(generation, revision);
    if (!session.valid(photos.map((p) => p.captureId))) {
      throw StateError(
        '${session.captureCount} valid still/clip pairs are required.',
      );
    }
    _export = null;
    _exportInput = null;
    final ordered = [...photos]..sort((a, b) => a.index.compareTo(b.index));
    final clips = ordered.map((p) => session.clip(p.captureId)!).toList();
    final designs = <BouncyDesign>[];
    for (final selection in selections) {
      final frame = classicLayout == null
          ? KeychainFrameCatalog.byId(selection.frameId)
          : FrameConstants.availableFrames.firstWhere(
              (frame) => frame.id == selection.frameId,
            );
      final layout = classicLayout == null
          ? frame.layouts.values.first
          : frame.layouts[classicLayout];
      if (layout == null) {
        throw StateError('Frame does not support this layout.');
      }
      final data = await FrameArtworkLoader.load(layout.frameAssetPath);
      _check(generation, revision);
      designs.add(
        BouncyDesign(
          layout,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          selection.filterId,
        ),
      );
    }
    _exportInput = (
      clips: List.unmodifiable(clips),
      designs: List.unmodifiable(designs),
    );
    final work = session.track(
      _runBouncyRender(
        clips,
        designs,
        () => session.generation == generation && _revision == revision,
      ),
    );
    _frames = work;
    _drain = work.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    final result = await work;
    _check(generation, revision);
    return result;
  }

  Future<String> export() {
    if (!session.motionEnabled) {
      return Future.error(
        StateError('Bouncy previews are off for this session.'),
      );
    }
    if (failEncoder) {
      return Future.error(
        StateError('QA encoder failure. Valid photos remain printable.'),
      );
    }
    final existing = _export;
    if (existing != null) return existing;
    final work = session.track(_encode());
    _export = work;
    work.catchError((Object error) {
      if (identical(_export, work)) _export = null;
      return '';
    });
    return work;
  }

  Future<String> _encode() async {
    final generation = session.generation;
    final revision = _revision;
    await (_preparation ?? _frames);
    final input = _exportInput;
    if (input == null) {
      throw StateError('Prepare the animated composition first.');
    }
    _check(generation, revision);
    if (failEncoder) {
      throw StateError('QA encoder failure. Valid photos remain printable.');
    }
    // Render directly from retained camera JPEGs, never enlarge the preview.
    final render = _runBouncyRender(
      input.clips,
      input.designs,
      () => session.generation == generation && _revision == revision,
      quality: BouncyRenderQuality.softCopy,
    );
    _drain = render.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    final frames = await render;
    _check(generation, revision);
    final dir = await Directory.systemTemp.createTemp('bouncy_export_');
    _directories.add(dir);
    final output = '${dir.path}/bouncy_preview.mp4';
    // A real encode is the capability probe; unsupported drivers fall back.
    Object? failure;
    for (final codec in encoders) {
      _check(generation, revision);
      try {
        final process = await Process.start('ffmpeg', [
          '-y',
          '-v',
          'error',
          '-f',
          'image2pipe',
          '-framerate',
          '6',
          '-vcodec',
          'png',
          '-i',
          'pipe:0',
          '-an',
          '-c:v',
          codec,
          ...bouncyEncoderQualityArguments(codec),
          '-pix_fmt',
          'yuv420p',
          '-movflags',
          '+faststart',
          output,
        ]);
        _process = process;
        final errors = process.stderr.transform(utf8.decoder).join();
        final stdoutDone = process.stdout.drain<void>();
        try {
          for (final frame in frames) {
            _check(generation, revision);
            process.stdin.add(frame);
            await process.stdin.flush();
          }
          await process.stdin.close();
        } catch (_) {
          process.kill();
        }
        final exit = await process.exitCode;
        await stdoutDone;
        final message = await errors;
        _process = null;
        _check(generation, revision);
        if (exit != 0) throw StateError('Encoder $codec failed: $message');
        final probe = await Process.run('ffprobe', [
          '-v',
          'error',
          '-show_entries',
          'stream=codec_type,width,height,duration,nb_frames',
          '-of',
          'json',
          output,
        ]);
        _check(generation, revision);
        if (probe.exitCode != 0 || !(await File(output).exists())) {
          throw StateError('Unable to validate the encoded MP4.');
        }
        final data = jsonDecode(probe.stdout as String) as Map<String, dynamic>;
        final streams = data['streams'] as List<dynamic>;
        if (streams.length != 1 ||
            (streams.first as Map<String, dynamic>)['codec_type'] != 'video') {
          throw StateError('Bouncy MP4 must contain one silent video stream.');
        }
        final video = streams.single as Map<String, dynamic>;
        final image = img.PngDecoder().startDecode(frames.first)!;
        final duration = double.tryParse('${video['duration']}') ?? 0;
        if (video['width'] != image.width ||
            video['height'] != image.height ||
            (duration - 6).abs() > 0.2 ||
            await File(output).length() < 1024) {
          throw StateError(
            'MP4 dimensions/duration do not match the complete composition.',
          );
        }
        final sample = await Process.run('ffmpeg', [
          '-v',
          'error',
          '-i',
          output,
          '-frames:v',
          '1',
          '-f',
          'null',
          '-',
        ]);
        _check(generation, revision);
        if (sample.exitCode != 0) {
          throw StateError('MP4 sample could not be decoded.');
        }
        encoder = codec;
        session.exportError = null;
        return output;
      } catch (error) {
        failure = error;
        _process?.kill();
        _process = null;
      }
    }
    session.exportError =
        'Motion export failed. Retry export; the photos remain printable.';
    _export = null;
    throw StateError('$failure');
  }

  void _check(int generation, int revision) {
    if (!session.motionEnabled ||
        session.generation != generation ||
        _revision != revision) {
      throw StateError('Animated composition was cancelled.');
    }
  }

  Future<void> cancelAndDrain() async {
    _revision++;
    _process?.kill();
    try {
      await _export;
    } catch (_) {}
    await _drain;
    _frames = null;
    _exportInput = null;
    _preparation = null;
    _export = null;
    for (final directory in _directories.toList()) {
      if (await directory.exists()) await directory.delete(recursive: true);
      _directories.remove(directory);
    }
  }
}

/// Six fps, 18 forward samples plus 18 reversed samples: exactly six seconds.
/// Decodes only four source frames plus one filter set at a time.
Future<List<Uint8List>> renderBouncyCycle(
  List<BouncyClip> clips,
  List<BouncyDesign> designs, {
  BouncyRenderQuality quality = BouncyRenderQuality.preview,
}) async {
  if (clips.isEmpty ||
      clips.length > 4 ||
      designs.isEmpty ||
      (designs.length != 1 && designs.length != 4) ||
      (designs.length == 4 && clips.length != 4)) {
    throw ArgumentError('Expected 1–4 clips for Classic or four for Keychain.');
  }
  final softCopy = quality == BouncyRenderQuality.softCopy;
  final tileWidth = softCopy && designs.length == 1 ? 620 : 310;
  final tileHeight = softCopy && designs.length == 1 ? 922 : 461;
  final artwork = designs
      .map(
        (d) => img.copyResize(
          img.decodeImage(d.artwork)!,
          width: tileWidth,
          height: tileHeight,
          interpolation: softCopy
              ? img.Interpolation.linear
              : img.Interpolation.nearest,
        ),
      )
      .toList();
  final forward = <Uint8List>[];
  var retained = 0;
  for (var tick = 0; tick < 18; tick++) {
    final elapsed = Duration(microseconds: (tick * 3000000 / 17).round());
    final sources = clips.map((clip) {
      final decoded = img.decodeImage(clip.at(elapsed));
      if (decoded == null) {
        throw StateError('A validated live view image became unreadable.');
      }
      final source =
          decoded.exif.imageIfd.hasOrientation &&
              decoded.exif.imageIfd.orientation != 1
          ? img.bakeOrientation(decoded)
          : decoded;
      final size = bouncyWorkingDimensions(
        source.width,
        source.height,
        maxSide: softCopy ? 640 : 320,
      );
      return size.width == source.width && size.height == source.height
          ? source
          : img.copyResize(
              source,
              width: size.width,
              height: size.height,
              interpolation: softCopy
                  ? img.Interpolation.linear
                  : img.Interpolation.nearest,
            );
    }).toList();
    final canvas = img.Image(
      width: designs.length == 4 ? tileWidth * 2 : tileWidth,
      height: designs.length == 4
          ? tileHeight * 2
          : tileHeight + tileHeight % 2,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    for (final filterId in designs.map((d) => d.filterId).toSet()) {
      final filter = KeychainFilterCatalog.byId(filterId);
      final filtered = filterId == 'no_filter'
          ? sources
          : [
              for (final source in sources)
                filter.applyFilter(img.Image.from(source)),
            ];
      for (var index = 0; index < designs.length; index++) {
        if (designs[index].filterId != filterId) continue;
        final tile = FrameCompositionRenderer.renderDecodedVariant(
          layout: designs[index].layout,
          frame: artwork[index],
          photos: filtered,
          sourcePhotoCount: clips.length,
          width: tileWidth,
          height: tileHeight,
        );
        img.compositeImage(
          canvas,
          tile,
          dstX: (index % 2) * tileWidth,
          dstY: (index ~/ 2) * tileHeight,
        );
      }
    }
    final encoded = Uint8List.fromList(img.encodePng(canvas));
    retained += encoded.length;
    if (retained > (softCopy ? 24 : 12) * 1024 * 1024) {
      throw StateError(
        'Animated composition exceeded its compressed memory budget.',
      );
    }
    forward.add(encoded);
  }
  // Reverse shares compressed buffers instead of duplicating retained bytes.
  return List.unmodifiable([...forward, ...forward.reversed]);
}

final bouncyMediaProvider = Provider<BouncyMediaService>((ref) {
  final service = BouncyMediaService(ref.read(bouncySessionProvider));
  ref.onDispose(service.dispose);
  return service;
});

final classicBouncyFrameProvider = StateProvider<String>(
  (ref) => FrameConstants.availableFrames.first.id,
);

class _RenderRequest {
  final List<BouncyClip> clips;
  final List<BouncyDesign> designs;
  final bool Function() current;
  final BouncyRenderQuality quality;
  final Completer<List<Uint8List>> completion = Completer();
  _RenderRequest(this.clips, this.designs, this.current, this.quality);
}

bool _rendering = false;
_RenderRequest? _queuedRender;
Future<List<Uint8List>> _runBouncyRender(
  List<BouncyClip> clips,
  List<BouncyDesign> designs,
  bool Function() current, {
  BouncyRenderQuality quality = BouncyRenderQuality.preview,
}) {
  final request = _RenderRequest(clips, designs, current, quality);
  if (_rendering) {
    _queuedRender?.completion.completeError(StateError('Preview superseded.'));
    _queuedRender = request;
  } else {
    unawaited(_renderRequest(request));
  }
  return request.completion.future;
}

Future<void> _renderRequest(_RenderRequest request) async {
  _rendering = true;
  try {
    if (!request.current()) throw StateError('Preview cancelled.');
    final result = await _renderInIsolate(
      request.clips,
      request.designs,
      request.quality,
    );
    if (!request.current()) throw StateError('Preview cancelled.');
    request.completion.complete(result);
  } catch (error, stack) {
    request.completion.completeError(error, stack);
  } finally {
    _rendering = false;
    final next = _queuedRender;
    _queuedRender = null;
    if (next != null) unawaited(_renderRequest(next));
  }
}

Future<List<Uint8List>> _renderInIsolate(
  List<BouncyClip> clips,
  List<BouncyDesign> designs,
  BouncyRenderQuality quality,
) => Isolate.run(() => renderBouncyCycle(clips, designs, quality: quality));

({int width, int height}) bouncyPreviewDimensions(int width, int height) =>
    bouncyWorkingDimensions(width, height, maxSide: 320);

({int width, int height}) bouncyWorkingDimensions(
  int width,
  int height, {
  required int maxSide,
}) {
  if (width <= 0 || height <= 0 || maxSide <= 0) {
    throw ArgumentError('Image dimensions must be positive.');
  }
  final largest = width > height ? width : height;
  final scale = largest > maxSide ? maxSide / largest : 1.0;
  final scaledWidth = (width * scale).round();
  final scaledHeight = (height * scale).round();
  return (
    width: scaledWidth < 1 ? 1 : scaledWidth,
    height: scaledHeight < 1 ? 1 : scaledHeight,
  );
}

List<String> bouncyEncoderQualityArguments(String codec) => switch (codec) {
  'h264_nvenc' => const ['-rc', 'vbr', '-cq', '21', '-b:v', '0'],
  'h264_qsv' => const ['-global_quality', '21'],
  'libx264' => const ['-preset', 'veryfast', '-crf', '21'],
  _ => const [],
};
