import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:printing/printing.dart';

class FlipbookArchivePreviewScreen extends ConsumerStatefulWidget {
  final Uint8List pdfBytes;
  final String frameName;

  const FlipbookArchivePreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.frameName,
  });

  @override
  ConsumerState<FlipbookArchivePreviewScreen> createState() =>
      _FlipbookArchivePreviewScreenState();
}

class _FlipbookArchivePreviewScreenState
    extends ConsumerState<FlipbookArchivePreviewScreen> {
  bool _isPrinting = false;

  Future<void> _reprint() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final printerNotifier = ref.read(printerProvider.notifier);
      await printerNotifier.printPdfBytesForVideo(widget.pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document sent to printer successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF76220B)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              // Header
              Row(
                children: [
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
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF76220B),
                        size: 28,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'Flipbook Archive',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFBEE),
                        ),
                      ),
                      Text(
                        widget.frameName,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 18,
                          color: const Color(0xFFFFFBEE).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 60),
                ],
              ),

              const SizedBox(height: 40),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Left panel - Reprint action
                    Expanded(
                      flex: 2,
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
                              'Reprint Options',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 32,
                                color: const Color(0xFFFFFBEE),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
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
                                        'Archive Info',
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
                                    '• Frame: ${widget.frameName}\n'
                                    '• This is a saved flipbook PDF\n'
                                    '• Reprint will send to the video printer',
                                    style: TextStyle(
                                      fontFamily: 'LeagueSpartan',
                                      fontSize: 16,
                                      color: const Color(
                                        0xFFFFFBEE,
                                      ).withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: ElevatedButton(
                                onPressed: _isPrinting ? null : _reprint,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: const Color(
                                                0xFF76220B,
                                              ).withOpacity(0.5),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.print_rounded, size: 32),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Reprint Flipbook',
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
                      ),
                    ),

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
                              'Preview',
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
                                    build: (format) => widget.pdfBytes,
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
