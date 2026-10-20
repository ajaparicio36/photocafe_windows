import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/services/bouncy_session.dart';

/// Explicit QA-only animated feed; never used to validate a real Canon capture.
class BouncyFixture {
  static const enabled = bool.fromEnvironment('BOUNCY_QA');
  Timer? _timer;
  final List<Uint8List> _frames = [];
  int _index = 0;
  String mode = 'valid';
  Future<void> start(BouncySession session) async {
    for (var i = 0; i < 36; i++) {
      final image = img.Image(width: 640, height: 360);
      img.fill(image, color: img.ColorRgb8(25 + i * 4, 80, 140));
      img.fillRect(
        image,
        x1: i * 14,
        y1: 70,
        x2: i * 14 + 90,
        y2: 290,
        color: img.ColorRgb8(255, 220, 100),
      );
      _frames.add(Uint8List.fromList(img.encodeJpg(image, quality: 82)));
    }
    _timer = Timer.periodic(const Duration(milliseconds: 83), (_) {
      _index = (_index + 1) % _frames.length;
      if (mode != 'missing') session.feed(_frames[_index]);
    });
  }

  Uint8List? get latest => _frames.isEmpty ? null : _frames[_index];
  Future<String> still() async {
    final directory = await Directory.systemTemp.createTemp('bouncy_fixture_');
    final file = File('${directory.path}/still.jpg');
    await file.writeAsBytes(_frames[_index]);
    return file.path;
  }

  void dispose() => _timer?.cancel();
}
