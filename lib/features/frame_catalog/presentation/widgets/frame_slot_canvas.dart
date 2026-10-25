import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/frame_catalog_models.dart';
import 'catalog_style.dart';

enum _SlotGesture { move, resize, rotate }

/// Editing geometry is expressed in the same logical points as the renderer.
/// Handles and hit targets stay screen-sized when the artwork is fitted.
class FrameSlotCanvas extends StatefulWidget {
  final FrameTemplate template;
  final Uint8List artwork;
  final String? selectedSlotId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<FrameSlot> onSlotChanged;
  final bool enabled;
  final bool showArtwork;

  const FrameSlotCanvas({
    super.key,
    required this.template,
    required this.artwork,
    required this.selectedSlotId,
    required this.onSelect,
    required this.onSlotChanged,
    this.enabled = true,
    this.showArtwork = true,
  });

  @override
  State<FrameSlotCanvas> createState() => _FrameSlotCanvasState();
}

class _FrameSlotCanvasState extends State<FrameSlotCanvas> {
  final _focusNode = FocusNode(debugLabel: 'Frame slot canvas');
  int? _pointer;
  FrameSlot? _startSlot;
  Offset? _startPoint;
  _SlotGesture? _gesture;
  bool _focused = false;

  FrameSlot? get _selected => widget.template.slots
      .where((slot) => slot.id == widget.selectedSlotId)
      .firstOrNull;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Offset _rotate(Offset point, double radians) => Offset(
    point.dx * math.cos(radians) - point.dy * math.sin(radians),
    point.dx * math.sin(radians) + point.dy * math.cos(radians),
  );

  Offset _center(FrameSlot slot) =>
      Offset(slot.left + slot.width / 2, slot.top + slot.height / 2);

  Offset _corner(FrameSlot slot) =>
      _center(slot) +
      _rotate(
        Offset(slot.width / 2, slot.height / 2),
        slot.rotationDegrees * math.pi / 180,
      );

  Offset _rotateHandle(FrameSlot slot, double scale) =>
      _center(slot) +
      _rotate(
        Offset(0, -slot.height / 2 - 30 / scale),
        slot.rotationDegrees * math.pi / 180,
      );

  void _start(PointerDownEvent event, Rect paper, double scale) {
    if (!widget.enabled || _pointer != null) return;
    _focusNode.requestFocus();
    final point = (event.localPosition - paper.topLeft) / scale;
    final selected = _selected;
    FrameSlot? hit;
    var gesture = _SlotGesture.move;
    if (selected != null) {
      if ((point - _rotateHandle(selected, scale)).distance * scale <= 22) {
        hit = selected;
        gesture = _SlotGesture.rotate;
      } else if ((point - _corner(selected)).distance * scale <= 22) {
        hit = selected;
        gesture = _SlotGesture.resize;
      }
    }
    hit ??= widget.template.slots.reversed.where((slot) {
      final local = _rotate(
        point - _center(slot),
        -slot.rotationDegrees * math.pi / 180,
      );
      return local.dx.abs() <= slot.width / 2 &&
          local.dy.abs() <= slot.height / 2;
    }).firstOrNull;
    widget.onSelect(hit?.id);
    if (hit == null) return;
    _pointer = event.pointer;
    _startSlot = hit;
    _startPoint = point;
    _gesture = gesture;
  }

  void _update(PointerMoveEvent event, Rect paper, double scale) {
    if (!widget.enabled || _pointer != event.pointer) return;
    final slot = _startSlot;
    final start = _startPoint;
    if (slot == null || start == null) return;
    final point = (event.localPosition - paper.topLeft) / scale;
    final delta = point - start;
    final radians = slot.rotationDegrees * math.pi / 180;
    switch (_gesture) {
      case _SlotGesture.move:
        widget.onSlotChanged(
          slot.copyWith(left: slot.left + delta.dx, top: slot.top + delta.dy),
        );
      case _SlotGesture.resize:
        final localDelta = _rotate(delta, -radians);
        final width = math.max(1.0, slot.width + localDelta.dx);
        final height = math.max(1.0, slot.height + localDelta.dy);
        // Keep the opposite rotated corner fixed while resizing.
        final anchor =
            _center(slot) -
            _rotate(Offset(slot.width / 2, slot.height / 2), radians);
        final center = anchor + _rotate(Offset(width / 2, height / 2), radians);
        widget.onSlotChanged(
          slot.copyWith(
            width: width,
            height: height,
            left: center.dx - width / 2,
            top: center.dy - height / 2,
          ),
        );
      case _SlotGesture.rotate:
        final center = _center(slot);
        final initial = math.atan2(start.dy - center.dy, start.dx - center.dx);
        final current = math.atan2(point.dy - center.dy, point.dx - center.dx);
        final degrees =
            (slot.rotationDegrees + (current - initial) * 180 / math.pi + 540) %
                360 -
            180;
        widget.onSlotChanged(slot.copyWith(rotationDegrees: degrees));
      case null:
        break;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final selected = _selected;
    if (selected == null) return KeyEventResult.ignored;
    final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
    final offset = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
      LogicalKeyboardKey.arrowRight => Offset(step, 0),
      LogicalKeyboardKey.arrowUp => Offset(0, -step),
      LogicalKeyboardKey.arrowDown => Offset(0, step),
      _ => null,
    };
    if (offset == null) return KeyEventResult.ignored;
    widget.onSlotChanged(
      selected.copyWith(
        left: selected.left + offset.dx,
        top: selected.top + offset.dy,
      ),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      onFocusChange: (value) => setState(() => _focused = value),
      child: Semantics(
        label: 'Frame layout canvas',
        hint:
            'Select a photo slot. Drag to move, drag the square to resize, '
            'or drag the round handle to rotate. Arrow keys move one point; '
            'Shift and arrow keys move ten points.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.max(
              0.01,
              math.min(
                (constraints.maxWidth - 88) / widget.template.canvasWidth,
                (constraints.maxHeight - 88) / widget.template.canvasHeight,
              ),
            );
            final size = Size(
              widget.template.canvasWidth * scale,
              widget.template.canvasHeight * scale,
            );
            final paper = Rect.fromCenter(
              center: constraints.biggest.center(Offset.zero),
              width: size.width,
              height: size.height,
            );
            return Listener(
              key: const ValueKey('frame-slot-canvas'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _start(event, paper, scale),
              onPointerMove: (event) => _update(event, paper, scale),
              onPointerUp: (event) {
                if (_pointer == event.pointer) _pointer = null;
              },
              onPointerCancel: (event) {
                if (_pointer == event.pointer) _pointer = null;
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E4E4),
                  border: Border.all(
                    color: _focused ? catalogInk : const Color(0xFFCCC4C4),
                    width: _focused ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _SlotsPainter(
                        template: widget.template,
                        paper: paper,
                        scale: scale,
                      ),
                    ),
                    if (widget.showArtwork)
                      Positioned.fromRect(
                        rect: paper,
                        child: IgnorePointer(
                          child: Image.memory(
                            widget.artwork,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stack) =>
                                const Center(
                                  child: Text('Artwork could not be displayed'),
                                ),
                          ),
                        ),
                      ),
                    CustomPaint(
                      painter: _SlotsPainter(
                        template: widget.template,
                        paper: paper,
                        scale: scale,
                        selectedSlotId: widget.selectedSlotId,
                        outlineOnly: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlotsPainter extends CustomPainter {
  final FrameTemplate template;
  final Rect paper;
  final double scale;
  final String? selectedSlotId;
  final bool outlineOnly;

  const _SlotsPainter({
    required this.template,
    required this.paper,
    required this.scale,
    this.selectedSlotId,
    this.outlineOnly = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!outlineOnly) {
      canvas.drawRect(paper, Paint()..color = Colors.white);
      // Transparency checkerboard belongs to the editing canvas only.
      canvas.save();
      canvas.clipRect(paper);
      for (var y = paper.top; y < paper.bottom; y += 12) {
        for (var x = paper.left; x < paper.right; x += 12) {
          final row = ((y - paper.top) / 12).round();
          final column = ((x - paper.left) / 12).round();
          if ((row + column).isEven) {
            canvas.drawRect(
              Rect.fromLTWH(x, y, 12, 12),
              Paint()..color = const Color(0xFFE9E9E9),
            );
          }
        }
      }
      canvas.restore();
    }
    for (final slot in template.slots) {
      final selected = slot.id == selectedSlotId;
      final width = slot.width * scale;
      final height = slot.height * scale;
      canvas.save();
      if (!outlineOnly) canvas.clipRect(paper);
      canvas.translate(
        paper.left + (slot.left + slot.width / 2) * scale,
        paper.top + (slot.top + slot.height / 2) * scale,
      );
      canvas.rotate(slot.rotationDegrees * math.pi / 180);
      final bounds = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      );
      if (!outlineOnly) {
        const colors = [
          Color(0xFFD0DCE8),
          Color(0xFFD8E4D5),
          Color(0xFFEADACB),
          Color(0xFFE1D7E9),
        ];
        canvas.drawRect(bounds, Paint()..color = colors[slot.photoIndex % 4]);
        final label = TextPainter(
          text: TextSpan(
            text: template.kind == FrameTemplateKind.flipbook
                ? 'Sequence image'
                : 'Photo ${slot.photoIndex + 1}',
            style: TextStyle(
              color: const Color(0xFF323039),
              fontSize: math.min(16, math.min(width / 6, height / 3)),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: math.max(1, width));
        label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
      } else {
        canvas.drawRect(
          bounds,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected ? 2.5 : 1
            ..color = selected ? const Color(0xFF145CCA) : catalogInk,
        );
        if (selected) {
          final handlePaint = Paint()..color = const Color(0xFF145CCA);
          canvas.drawRect(
            Rect.fromCenter(center: bounds.bottomRight, width: 18, height: 18),
            handlePaint,
          );
          final rotatePoint = Offset(0, bounds.top - 30);
          canvas.drawLine(
            Offset(0, bounds.top),
            rotatePoint,
            handlePaint..strokeWidth = 2,
          );
          canvas.drawCircle(rotatePoint, 11, handlePaint);
          final icon = Icons.rotate_right;
          final glyph = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          glyph.paint(
            canvas,
            rotatePoint - Offset(glyph.width / 2, glyph.height / 2),
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SlotsPainter oldDelegate) =>
      oldDelegate.template != template ||
      oldDelegate.paper != paper ||
      oldDelegate.selectedSlotId != selectedSlotId ||
      oldDelegate.outlineOnly != outlineOnly;
}
