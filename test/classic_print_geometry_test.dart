import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/classic_frame_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Classic PDF paths fill the native printer page without compensation',
    () async {
      final widget = ClassicFrameWidget(
        frameDefinition: FrameConstants.availableFrames.first,
      );
      const layout = FrameConstants.fourFrameTwelve;
      final documents = [
        await widget.generatePdfFromLayout([], 4, layout),
        await widget.generatePdfFromLayoutWithRotations([], 4, layout, []),
      ];
      for (final bytes in documents) {
        final pdf = latin1.decode(bytes);
        expect(pdf.contains('/MediaBox[0 0 297.6 442.56]'), isTrue);
        final content = _pageContent(bytes);
        // Full-page frame image matrix: native dimensions and zero translation.
        expect(content, contains('297.6 0 0 442.56 0 0 cm /I'));
        expect(content, isNot(contains('0.94 0 0 0.94')));
        expect(content, isNot(contains('1.005 0 0 1.005')));
        // Existing slots retain their original point coordinates and sizes.
        final slot = layout.leftColumnPositions.first;
        expect(
          content,
          contains(
            '${slot.width.toStringAsFixed(0)} ${slot.height.toStringAsFixed(0)} re',
          ),
        );
      }
    },
  );
}

String _pageContent(Uint8List bytes) {
  final text = latin1.decode(bytes);
  final streams = RegExp(
    r'<</Filter/FlateDecode/Length (\d+)>>stream\r?\n',
  ).allMatches(text);
  for (final stream in streams) {
    final length = int.parse(stream.group(1)!);
    final content = latin1.decode(
      ZLibCodec().decode(bytes.sublist(stream.end, stream.end + length)),
    );
    if (content.contains(' cm /I')) return content;
  }
  throw StateError('PDF page content not found');
}
