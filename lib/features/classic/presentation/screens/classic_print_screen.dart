import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:printing/printing.dart';

class ClassicPrintScreen extends ConsumerStatefulWidget {
  final Uint8List? pdfBytes;

  const ClassicPrintScreen({super.key, this.pdfBytes});

  @override
  ConsumerState<ClassicPrintScreen> createState() => _ClassicPrintScreenState();
}

class _ClassicPrintScreenState extends ConsumerState<ClassicPrintScreen> {
  bool _isPrinting = false;
  bool _splitStrips = true;
  Uint8List? _actualPdfBytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get PDF bytes from router state if not provided in constructor
    if (widget.pdfBytes == null) {
      final routerState = GoRouterState.of(context);
      _actualPdfBytes = routerState.extra as Uint8List?;
    } else {
      _actualPdfBytes = widget.pdfBytes;
    }
  }

  Future<void> _printDocument(int copies) async {
    if (_actualPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'No PDF available to print',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final printerNotifier = ref.read(printerProvider.notifier);
      await printerNotifier.printPdfBytes(
        _actualPdfBytes!,
        cut: _splitStrips,
        copies: copies,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Document sent to printer successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      _showPrintCompletionDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Print failed: $e',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
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
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEE).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.error_rounded,
                          size: 60,
                          color: const Color(0xFFFFFBEE),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No PDF Available',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: 36,
                              color: const Color(0xFFFFFBEE),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please go back and generate the PDF first.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 20,
                          color: const Color(0xFFFFFBEE).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () => context.go('/classic/organize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEE),
                            foregroundColor: const Color(0xFF76220B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Go Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
                            onPressed: () => context.go('/classic/organize'),
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
                              'Print Preview',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFBEE),
                              ),
                            ),
                            Text(
                              'Review your photo strip before printing',
                              style: TextStyle(
                                fontSize: 18,
                                color: const Color(0xFFFFFBEE).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Empty spacer to balance the layout
                        SizedBox(width: 60),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Main content area
                    Expanded(
                      child: Row(
                        children: [
                          // Left panel - Action buttons
                          Expanded(
                            flex: 2,
                            child: PrintActionPanel(
                              isPrinting: _isPrinting,
                              splitStrips: _splitStrips,
                              pdfBytes: _actualPdfBytes,
                              onSplitStripsChanged: (value) {
                                setState(() {
                                  _splitStrips = value;
                                });
                              },
                              onPrint: _printDocument,
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
                                    'Final Preview',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFFFBEE),
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  // PDF Preview
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: PdfPreview(
                                          build: (format) => _actualPdfBytes!,
                                          canChangePageFormat: false,
                                          canDebug: false,
                                          allowPrinting: false,
                                          allowSharing: false,
                                          useActions: false,
                                          scrollViewDecoration: BoxDecoration(
                                            color: Colors.grey[50],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Preview info
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFFBEE,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 28,
                                          color: const Color(0xFFFFFBEE),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'This is how your photo strip will look when printed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFFFFFBEE,
                                                  ),
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
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showPrintCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        backgroundColor: const Color(0xFFFFFBEE),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF76220B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: const Color(0xFF76220B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Print Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF76220B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your photos have been printed successfully.\nThank you for using Click Click Photobooth!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: const Color(0xFF76220B).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(photoProvider.notifier).clearAllPhotos();
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76220B),
                  foregroundColor: const Color(0xFFFFFBEE),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Start Over',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
