import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

class BouncyFrame {
  final int micros;
  final Uint8List jpeg;
  BouncyFrame(this.micros, Uint8List jpeg)
    : jpeg = Uint8List.fromList(jpeg).asUnmodifiableView();
}

class BouncyClip {
  final List<BouncyFrame> frames;
  final int shutterMicros;
  final bool verified;
  BouncyClip(List<BouncyFrame> frames, this.shutterMicros)
    : frames = List.unmodifiable(frames),
      verified = false;
  BouncyClip._verified(List<BouncyFrame> frames, this.shutterMicros)
    : frames = List.unmodifiable(frames),
      verified = true;
  int get bytes => frames.fold(0, (sum, frame) => sum + frame.jpeg.length);
  String? get problem {
    if (frames.any((f) => f.micros < 0 || f.micros > shutterMicros)) {
      return 'Invalid live view timestamp.';
    }
    // Accept the history the camera supplied, even if it is short or sparse.
    if (frames.isEmpty) return 'Live view clip is missing.';
    if (shutterMicros - frames.last.micros > 250000) {
      return 'Live view stopped before the shutter.';
    }
    for (var i = 1; i < frames.length; i++) {
      if (frames[i].micros <= frames[i - 1].micros ||
          frames[i].micros - frames[i - 1].micros > 350000) {
        return 'Live view was interrupted. Retake this shot.';
      }
    }
    return null;
  }

  Uint8List at(Duration elapsed) {
    final phase = elapsed.inMicroseconds % 6000000;
    final forward = phase <= 3000000 ? phase : 6000000 - phase;
    final target = shutterMicros - 3000000 + forward;
    return frames
        .lastWhere((f) => f.micros <= target, orElse: () => frames.first)
        .jpeg;
  }
}

/// A compressed EVF ring. Time, frame count and bytes are independent caps.
class BouncyRing {
  static const durationMicros = 3000000;
  final int maxFrames;
  final int maxBytes;
  final Queue<BouncyFrame> _frames = Queue();
  int bytes = 0;
  BouncyRing({this.maxFrames = 48, this.maxBytes = 12 * 1024 * 1024});
  int get length => _frames.length;
  void clear() {
    _frames.clear();
    bytes = 0;
  }

  void add(int micros, Uint8List jpeg) {
    if (micros < 0 || jpeg.isEmpty || jpeg.length > maxBytes) return;
    // Sample at <= 12 fps before retaining compressed data.
    if (_frames.isNotEmpty && micros - _frames.last.micros < 80000) return;
    final frame = BouncyFrame(micros, jpeg);
    _frames.add(frame);
    bytes += jpeg.length;
    while (_frames.isNotEmpty &&
        (_frames.length > maxFrames ||
            bytes > maxBytes ||
            micros - _frames.first.micros > durationMicros)) {
      bytes -= _frames.removeFirst().jpeg.length;
    }
  }

  BouncyClip freeze(int shutterMicros) => BouncyClip(
    _frames
        .where(
          (f) =>
              f.micros <= shutterMicros &&
              shutterMicros - f.micros <= durationMicros,
        )
        .toList(),
    shutterMicros,
  );
}

class BouncyAttempt {
  final int session;
  final int number;
  final String captureId;
  const BouncyAttempt(this.session, this.number, this.captureId);
}

/// Session identity is separate from placement; reordering never changes clips.
class BouncySession extends ChangeNotifier {
  static const retainedByteLimit = 48 * 1024 * 1024;
  final clock = Stopwatch()..start();
  final ring = BouncyRing();
  final Map<String, BouncyClip> _clips = {};
  final Map<String, int> _attempts = {};
  int generation = 0;
  int _serial = 0;
  final Set<Future<void>> _pending = {};
  final Set<VoidCallback> cancellations = {};
  Future<T> track<T>(Future<T> work) {
    late final Future<void> done;
    done = work
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .whenComplete(() => _pending.remove(done));
    _pending.add(done);
    return work;
  }

  Future<void> drain() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }

  String classicFilterId = 'no_filter';
  String? exportError;
  int get retainedBytes => _clips.values.fold(0, (n, c) => n + c.bytes);
  int get pairCount => _clips.length;
  bool get hasWork =>
      _clips.isNotEmpty || _attempts.isNotEmpty || _pending.isNotEmpty;
  bool valid(Iterable<String> ids) =>
      ids.length == 4 &&
      ids.toSet().length == 4 &&
      ids.every((id) => _clips.containsKey(id) && !_attempts.containsKey(id));
  BouncyClip? clip(String id) => _clips[id];
  void feed(Uint8List jpeg) => ring.add(clock.elapsedMicroseconds, jpeg);
  BouncyAttempt attempt(String id) {
    if (!_clips.containsKey(id) &&
        !_attempts.containsKey(id) &&
        {..._clips.keys, ..._attempts.keys}.length >= 4) {
      throw StateError(
        'A Bouncy session contains exactly four shot identities.',
      );
    }
    _attempts[id] = ++_serial;
    return BouncyAttempt(generation, _serial, id);
  }

  bool current(BouncyAttempt attempt) =>
      attempt.session == generation &&
      _attempts[attempt.captureId] == attempt.number;
  BouncyClip freeze() => ring.freeze(clock.elapsedMicroseconds);
  bool get hasFreshPreview {
    final clip = freeze();
    return clip.frames.isNotEmpty &&
        clock.elapsedMicroseconds - clip.frames.last.micros <= 250000;
  }

  void accept(BouncyAttempt attempt, BouncyClip clip) {
    if (!current(attempt)) throw StateError('Capture session changed.');
    if (clip.problem != null) throw StateError(clip.problem!);
    if (!clip.verified) {
      throw StateError('Clip images have not been validated.');
    }
    final previous = _clips[attempt.captureId]?.bytes ?? 0;
    if ((!_clips.containsKey(attempt.captureId) && _clips.length >= 4) ||
        retainedBytes - previous + clip.bytes > retainedByteLimit) {
      throw StateError('Live view memory budget exceeded. Retake this shot.');
    }
    _clips[attempt.captureId] = clip;
    _attempts.remove(attempt.captureId);
    notifyListeners();
  }

  void reset() {
    generation++;
    for (final cancel in cancellations.toList()) {
      cancel();
    }
    ring.clear();
    _clips.clear();
    _attempts.clear();
    classicFilterId = 'no_filter';
    exportError = null;
    notifyListeners();
  }

  static int countdown({required int shot, required bool retake}) =>
      shot == 0 && !retake ? 10 : 3;
}

final bouncySessionProvider = ChangeNotifierProvider<BouncySession>(
  (ref) => BouncySession(),
);

BouncyClip validateBouncyImages(BouncyClip clip) {
  if (clip.problem != null) throw StateError(clip.problem!);
  if (clip.frames.length > 48 || clip.bytes > 12 * 1024 * 1024) {
    throw StateError('Live view clip exceeds the capture memory budget.');
  }
  try {
    for (final frame in clip.frames) {
      final decoder = img.JpegDecoder();
      final info = decoder.startDecode(frame.jpeg);
      if (info == null ||
          info.width < 16 ||
          info.height < 16 ||
          info.width * info.height > 1920 * 1080 ||
          decoder.decodeFrame(0) == null) {
        throw StateError('Unusable live view image.');
      }
    }
  } catch (_) {
    throw StateError(
      'Live view clip contains an unusable image. Retake this shot.',
    );
  }
  return BouncyClip._verified(clip.frames, clip.shutterMicros);
}

Future<BouncyClip> validateBouncyClipAsync(BouncyClip clip) =>
    Isolate.run(() => validateBouncyImages(clip));
