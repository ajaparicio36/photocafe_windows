import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/event_pdf_preview.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookPrintScreen extends ConsumerStatefulWidget {
  final Uint8List? pdfBytes;
  const FlipbookPrintScreen({super.key, this.pdfBytes});

  @override
  ConsumerState<FlipbookPrintScreen> createState() =>
      _FlipbookPrintScreenState();
}

class _FlipbookPrintScreenState extends ConsumerState<FlipbookPrintScreen> {
  bool _isPrinting = false;
  Uint8List? _actualPdfBytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pdfBytes == null) {
      final routerState = GoRouterState.of(context);
      _actualPdfBytes = routerState.extra as Uint8List?;
    } else {
      _actualPdfBytes = widget.pdfBytes;
    }
  }

  Future<void> _printDocument() async {
    if (_actualPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available to print')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final printerNotifier = ref.read(printerProvider.notifier);
      // Flipbooks should always be cut
      await printerNotifier.printPdfBytesForVideo(_actualPdfBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document sent to printer successfully!')),
      );

      _showPrintCompletionDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  void _showPrintCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF740000),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Print Complete!',
                  style: TextStyle(
                    fontFamily: EventDesign.body,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your flipbook has been printed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: EventDesign.body,
                    fontSize: 18,
                    color: const Color(0xFF740000).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(videoProvider.notifier).clearVideo();
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF740000),
                      foregroundColor: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Start Over',
                      style: TextStyle(
                        fontFamily: EventDesign.body,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EventPage(
    title: 'Print flipbook',
    subtitle: 'Review your complete pages before printing',
    onBack: _isPrinting ? null : () => context.go('/flipbook/frame'),
    child: _actualPdfBytes == null
        ? EventMessage(
            message: 'Choose a frame to prepare your flipbook.',
            action: EventButton(
              label: 'CHOOSE A FRAME',
              onPressed: () => context.go('/flipbook/frame'),
            ),
          )
        : Row(
            children: [
              Expanded(
                flex: 4,
                child: EventSection(
                  title: 'Your flipbook',
                  child: EventPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'READY TO FLIP',
                          style: TextStyle(
                            fontFamily: EventDesign.body,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Your flipbook will be printed with cut marks. The pages will be ready for binding.',
                          style: TextStyle(
                            fontFamily: EventDesign.body,
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        const Spacer(),
                        EventButton(
                          label: _isPrinting ? 'PRINTING…' : 'PRINT FLIPBOOK',
                          icon: Icons.print_outlined,
                          onPressed: _isPrinting ? null : _printDocument,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                flex: 6,
                child: EventSection(
                  title: 'Complete page',
                  figure: 'assets/event/frames_figure1.png',
                  figureWidth: 180,
                  child: EventPanel(
                    light: true,
                    child: EventPdfPreview(bytes: _actualPdfBytes!),
                  ),
                ),
              ),
            ],
          ),
  );
}
