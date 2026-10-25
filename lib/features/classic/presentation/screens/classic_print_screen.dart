import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/confirm_discard_session.dart';
import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';

class ClassicPrintScreen extends ConsumerStatefulWidget {
  final Uint8List? pdfBytes;
  final bool? isLandscape;

  const ClassicPrintScreen({super.key, this.pdfBytes, this.isLandscape});

  @override
  ConsumerState<ClassicPrintScreen> createState() => _ClassicPrintScreenState();
}

class _ClassicPrintScreenState extends ConsumerState<ClassicPrintScreen> {
  bool _isPrinting = false;
  bool _splitStrips = true;
  Uint8List? _actualPdfBytes;
  bool _isLandscape = false;
  bool _framePdfSaved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get PDF bytes from router state if not provided in constructor
    if (widget.pdfBytes == null) {
      final routerState = GoRouterState.of(context);
      final extra = routerState.extra;
      if (extra is Map<String, dynamic>) {
        _actualPdfBytes = extra['pdfBytes'] as Uint8List?;
        _isLandscape = extra['isLandscape'] as bool? ?? false;
      } else {
        _actualPdfBytes = extra as Uint8List?;
      }
    } else {
      _actualPdfBytes = widget.pdfBytes;
      _isLandscape = widget.isLandscape ?? false;
    }

    // Save the frame PDF to the photos temp directory so it's persisted
    // alongside the captured photos for the user and soft-copy uploads.
    if (_actualPdfBytes != null && !_framePdfSaved) {
      _framePdfSaved = true;
      ref
          .read(photoProvider.notifier)
          .saveFramePdf(_actualPdfBytes!)
          .then((path) => print('Frame PDF persisted to photos temp: $path'))
          .catchError((e) => print('Warning: Could not save frame PDF: $e'));
    }
  }

  Future<void> _printDocument(int copies) async {
    if (!ref
        .read(bouncySessionProvider)
        .valid(
          ref.read(photoProvider).value?.photos.map((p) => p.captureId) ?? [],
        )) {
      return;
    }
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
      if (!mounted) return;

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
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photoProvider).value?.photos ?? [];
    final printer = ref.watch(printerProvider).value;
    final layout = _isLandscape
        ? FrameLayoutType.fourLandscapePhotos
        : printer?.layoutMode == 2
        ? FrameLayoutType.twoPhotos
        : FrameLayoutType.fourPhotos;
    return EventPage(
      title: 'Print preview',
      subtitle: 'Keep your clicks in print and on your phone',
      onBack: () => context.go('/classic/organize'),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: EventSection(
              title: 'Your photos',
              child: PrintActionPanel(
                isPrinting: _isPrinting,
                printReady: _actualPdfBytes != null,
                splitStrips: _splitStrips,
                pdfBytes: _actualPdfBytes,
                onSplitStripsChanged: (value) =>
                    setState(() => _splitStrips = value),
                onPrint: _printDocument,
              ),
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 6,
            child: EventSection(
              title: 'Preview',
              figure: 'assets/event/frames_figure1.png',
              figureWidth: 180,
              child: EventPanel(
                child: BouncyPreview(
                  foregroundColor: Colors.white,
                  archive: true,
                  photos: photos,
                  selections: [
                    KeychainVariantSelection(
                      frameId: ref.watch(classicBouncyFrameProvider),
                      filterId: ref
                          .watch(bouncySessionProvider)
                          .classicFilterId,
                    ),
                  ],
                  classicLayout: layout,
                ),
              ),
            ),
          ),
        ],
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
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF740000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Color(0xFF740000),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Print Complete!',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF740000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your photos have been printed successfully.\nThank you for using Click Click Photobooth!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 18,
                color: Color(0xFF740000).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (!await confirmDiscardSession(this.context) || !mounted)
                    return;
                  await ref.read(photoProvider.notifier).clearAllPhotos();
                  if (mounted) this.context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF740000),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Start Over',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
