import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/print/print_action_panel.dart';
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
      await printerNotifier.printPdfBytes(_actualPdfBytes!, cut: true);

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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Print Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your flipbook has been printed successfully.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                child: const Text(
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

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      child: _actualPdfBytes == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No PDF available to print.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/flipbook/frame'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const ScreenHeader(
                  title: 'Print Flipbook',
                  subtitle: 'Review your flipbook before printing',
                  backRoute: '/flipbook/frame',
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FlipbookPrintActionPanel(
                          isPrinting: _isPrinting,
                          onPrint: _printDocument,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
