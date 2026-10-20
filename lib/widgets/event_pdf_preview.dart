import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:photocafe_windows/widgets/event_design.dart';

/// Shows one complete physical PDF page at a time, fitted on both axes.
/// Pagination keeps long Flipbooks usable without a scrolling/cropped sheet.
class EventPdfPreview extends StatefulWidget {
  const EventPdfPreview({super.key, required this.bytes, this.pageCount = 25});
  final Uint8List bytes;
  final int pageCount;
  @override
  State<EventPdfPreview> createState() => _EventPdfPreviewState();
}

class _EventPdfPreviewState extends State<EventPdfPreview> {
  int _page = 0;
  late Future<Uint8List> _image = _raster();

  Future<Uint8List> _raster() async {
    final raster = await Printing.raster(
      widget.bytes,
      pages: [_page],
      dpi: 110,
    ).first;
    return raster.toPng();
  }

  @override
  void didUpdateWidget(EventPdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _page = 0;
      _image = _raster();
    }
  }

  void _selectPage(int page) => setState(() {
    _page = page;
    _image = _raster();
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: FutureBuilder<Uint8List>(
          future: _image,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Preview could not load.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => _selectPage(_page),
                      child: const Text('Retry preview'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: 'Complete print page ${_page + 1}',
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous print page',
            onPressed: _page > 0 ? () => _selectPage(_page - 1) : null,
            icon: const Icon(Icons.chevron_left, color: EventDesign.red),
          ),
          Text(
            'Page ${_page + 1} of ${widget.pageCount}',
            style: const TextStyle(
              color: EventDesign.red,
              fontFamily: EventDesign.body,
              fontSize: 13,
            ),
          ),
          IconButton(
            tooltip: 'Next print page',
            onPressed: _page + 1 < widget.pageCount
                ? () => _selectPage(_page + 1)
                : null,
            icon: const Icon(Icons.chevron_right, color: EventDesign.red),
          ),
        ],
      ),
    ],
  );
}
