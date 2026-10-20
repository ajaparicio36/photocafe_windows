import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/services/bouncy_session.dart';

void main() {
  final jpeg = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 32, height: 18)),
  );
  BouncyClip clip({int offset = 0}) => validateBouncyImages(
    BouncyClip([
      for (var i = 0; i <= 30; i++) BouncyFrame(offset + i * 100000, jpeg),
    ], offset + 3000000),
  );
  test(
    'ring is bounded independently by time, count, bytes and immutable input',
    () {
      final ring = BouncyRing(maxFrames: 4, maxBytes: 10);
      final input = Uint8List.fromList([1, 2, 3]);
      for (var i = 0; i < 60; i++) {
        ring.add(i * 100000, input);
      }
      input[0] = 9;
      expect(ring.length, 3);
      expect(ring.bytes, 9);
      final frozen = ring.freeze(5900000);
      expect(frozen.frames.first.jpeg.first, 1);
      expect(() => frozen.frames.first.jpeg[0] = 7, throwsUnsupportedError);
      ring.add(10000000, Uint8List.fromList([4]));
      expect(ring.length, 1);
    },
  );
  test('independent frame cap and retained clip count are bounded', () {
    final ring = BouncyRing(maxFrames: 4, maxBytes: 1000);
    for (var i = 0; i < 12; i++) {
      ring.add(i * 100000, Uint8List.fromList([1, 2, 3]));
    }
    expect(ring.length, 4);
    expect(ring.bytes, 12);
    final session = BouncySession();
    addTearDown(session.dispose);
    for (var i = 0; i < 4; i++) {
      session.accept(session.attempt('shot$i'), clip());
    }
    expect(
      () => session.accept(session.attempt('fifth'), clip()),
      throwsStateError,
    );
    expect(
      session.retainedBytes,
      lessThanOrEqualTo(BouncySession.retainedByteLimit),
    );
  });
  test(
    'coverage, gaps, stale, missing, corrupt and future clips cannot complete',
    () {
      expect(BouncyClip([], 3000000).problem, isNotNull);
      final valid = clip();
      expect(valid.problem, isNull);
      expect(BouncyClip(valid.frames.sublist(20), 3000000).problem, isNotNull);
      expect(BouncyClip(valid.frames, 4000000).problem, isNotNull);
      expect(
        BouncyClip([
          ...valid.frames.take(5),
          ...valid.frames.skip(12),
        ], 3000000).problem,
        isNotNull,
      );
      expect(
        BouncyClip(valid.frames.reversed.toList(), 3000000).problem,
        isNotNull,
      );
      expect(BouncyClip(valid.frames, 2800000).problem, isNotNull);
      final corrupt = BouncyClip([
        for (var i = 0; i <= 30; i++)
          BouncyFrame(i * 100000, Uint8List.fromList([1, 2])),
      ], 3000000);
      expect(() => validateBouncyImages(corrupt), throwsStateError);
    },
  );
  test(
    'stable IDs, atomic retake, superseded attempts and session fencing',
    () {
      final session = BouncySession();
      addTearDown(session.dispose);
      for (var i = 0; i < 4; i++) {
        session.accept(session.attempt('shot$i'), clip());
      }
      expect(session.valid(['shot3', 'shot1', 'shot0', 'shot2']), isTrue);
      expect(session.valid(['shot0', 'shot0', 'shot0', 'shot0']), isFalse);
      final other = session.clip('shot1');
      final old = session.attempt('shot0');
      final replacement = session.attempt('shot0');
      expect(session.valid(['shot0', 'shot1', 'shot2', 'shot3']), isFalse);
      expect(
        () => session.accept(old, clip(offset: 1000000)),
        throwsStateError,
      );
      session.accept(replacement, clip(offset: 1000000));
      expect(session.clip('shot1'), same(other));
      expect(session.clip('shot0')!.shutterMicros, 4000000);
      expect(() => session.accept(replacement, clip()), throwsStateError);
      final late = session.attempt('shot2');
      session.reset();
      expect(() => session.accept(late, clip()), throwsStateError);
      expect(session.pairCount, 0);
    },
  );
  test('countdown first ten, later and every staff retake three', () {
    expect(BouncySession.countdown(shot: 0, retake: false), 10);
    for (var shot = 0; shot < 4; shot++) {
      expect(BouncySession.countdown(shot: shot, retake: true), 3);
      if (shot > 0) {
        expect(BouncySession.countdown(shot: shot, retake: false), 3);
      }
    }
  });
  test(
    'drain waits for owned work even after reset and cancellation fires once',
    () async {
      final session = BouncySession();
      addTearDown(session.dispose);
      final completion = Completer<void>();
      var cancelled = 0;
      session.cancellations.add(() => cancelled++);
      session.track(completion.future);
      session.reset();
      var drained = false;
      final draining = session.drain().then((_) => drained = true);
      await Future<void>.delayed(Duration.zero);
      expect(drained, isFalse);
      expect(cancelled, 1);
      completion.complete();
      await draining;
      expect(drained, isTrue);
    },
  );
}
