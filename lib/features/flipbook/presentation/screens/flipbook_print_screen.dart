import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:printing/printing.dart';

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
              color: const Color(0xFFFFFBEE),
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
                    color: const Color(0xFF76220B),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: Color(0xFFFFFBEE),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Print Complete!',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF76220B),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your flipbook has been printed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    color: const Color(0xFF76220B).withOpacity(0.7),
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
                      backgroundColor: const Color(0xFF76220B),
                      foregroundColor: const Color(0xFFFFFBEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Start Over',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
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

  Widget _buildPrintActionPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF76220B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Print Options',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 32,
              color: const Color(0xFFFFFBEE),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Print info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF5A1908),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFFFBEE),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Print Information',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFFBEE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• Flipbook will be printed with cut marks\n• Pages will be ready for binding\n• High quality print settings applied',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 16,
                    color: const Color(0xFFFFFBEE).withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Print button
          Container(
            width: double.infinity,
            height: 80,
            child: ElevatedButton(
              onPressed: _isPrinting ? null : _printDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPrinting
                    ? const Color(0xFFFFFBEE).withOpacity(0.5)
                    : const Color(0xFFFFFBEE),
                foregroundColor: _isPrinting
                    ? const Color(0xFF76220B).withOpacity(0.5)
                    : const Color(0xFF76220B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.transparent,
              ),
              child: _isPrinting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: const Color(0xFF76220B).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Printing...',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_rounded, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          'Print Flipbook',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF76220B)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: _actualPdfBytes == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: const Color(0xFFFFFBEE).withOpacity(0.4),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No PDF available to print',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 24,
                          color: const Color(0xFFFFFBEE),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 200,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => context.go('/flipbook/frame'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEE),
                            foregroundColor: const Color(0xFF76220B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Go Back',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        // Back button
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEE),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => context.go('/flipbook/frame'),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF76220B),
                              size: 28,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Title section
                        Column(
                          children: [
                            Text(
                              'Print Flipbook',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFBEE),
                              ),
                            ),
                            Text(
                              'Review your flipbook before printing',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 18,
                                color: const Color(0xFFFFFBEE).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Placeholder for symmetry
                        const SizedBox(width: 60),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Main content area
                    Expanded(
                      child: Row(
                        children: [
                          // Left panel - Print actions
                          Expanded(flex: 2, child: _buildPrintActionPanel()),

                          const SizedBox(width: 32),

                          // Right panel - PDF preview
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: const Color(0xFF76220B),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Final Preview',
                                    style: TextStyle(
                                      fontFamily: 'LeagueSpartan',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFFBEE),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFFFFBEE),
                                          width: 4,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: PdfPreview(
                                          build: (format) => _actualPdfBytes!,
                                          canChangePageFormat: false,
                                          canDebug: false,
                                          allowPrinting: false,
                                          allowSharing: false,
                                          useActions: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
