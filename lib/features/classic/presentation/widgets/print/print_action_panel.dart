import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/services/soft_copies_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrintActionPanel extends ConsumerStatefulWidget {
  final bool isPrinting;
  final bool splitStrips;
  final ValueChanged<bool> onSplitStripsChanged;
  final ValueChanged<int> onPrint;
  final Uint8List? pdfBytes;

  const PrintActionPanel({
    super.key,
    required this.isPrinting,
    required this.splitStrips,
    required this.onSplitStripsChanged,
    required this.onPrint,
    this.pdfBytes,
  });

  @override
  ConsumerState<PrintActionPanel> createState() => _PrintActionPanelState();
}

class _PrintActionPanelState extends ConsumerState<PrintActionPanel> {
  int _copies = 1;
  bool _isProcessingSoftCopies = false;
  double _processingProgress = 0.0;
  String _processingStatus = '';

  Future<void> _handleSoftCopies() async {
    setState(() {
      _isProcessingSoftCopies = true;
      _processingProgress = 0.0;
      _processingStatus = 'Preparing media files...';
    });

    try {
      final photoNotifier = ref.read(photoProvider.notifier);

      // Step 1: Get all media files
      setState(() {
        _processingStatus = 'Collecting photos...';
        _processingProgress = 0.1;
      });

      final mediaFiles = await photoNotifier.getAllMediaFiles();
      print('Media files collected: ${mediaFiles.length}');

      // Step 2: Get processed video (waits for background VHS processing if still running)
      String? processedVideoPath;
      final photoState = ref.read(photoProvider).value;

      if (photoState?.videoPath != null) {
        setState(() {
          _processingStatus = photoNotifier.isVhsProcessingInProgress
              ? 'Waiting for video processing...'
              : 'Getting processed video...';
        });

        try {
          // This will wait for background processing to complete if still running
          final processedVideo = await photoNotifier.getProcessedVideo();
          processedVideoPath = processedVideo?.path;

          if (processedVideoPath != null) {
            print('Video processing completed: $processedVideoPath');
            setState(() {
              _processingProgress = 0.5;
            });
          } else {
            // Fallback: process video on-demand if no processed video found
            setState(() {
              _processingStatus = 'Applying VHS filter to video...';
            });

            processedVideoPath = await photoNotifier.processVideoWithVHSFilter(
              onProgress: (progress) {
                setState(() {
                  _processingProgress = 0.1 + (progress * 0.4); // 0.1 to 0.5
                });
              },
            );
            print('On-demand video processing completed: $processedVideoPath');
          }
        } catch (e) {
          print('Video processing failed: $e');
          // Continue without video
        }
      } else {
        setState(() {
          _processingProgress = 0.5;
        });
      }

      // Step 3: Upload to server
      setState(() {
        _processingStatus = 'Uploading to server...';
      });

      final softCopiesService = SoftCopiesService();
      final result = await softCopiesService.uploadMediaFiles(
        mediaFiles: mediaFiles,
        processedVideoPath: processedVideoPath,
        pdfBytes: widget.pdfBytes,
        onProgress: (progress) {
          setState(() {
            _processingProgress = 0.5 + (progress * 0.5); // 0.5 to 1.0
          });
        },
      );

      if (result.success) {
        setState(() {
          _processingStatus = 'Upload complete!';
          _processingProgress = 1.0;
        });

        // Show success dialog with QR code
        _showSoftCopiesSuccessDialog(result.downloadUrl!);
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      print('Error in soft copies processing: $e');
      setState(() {
        _isProcessingSoftCopies = false;
        _processingProgress = 0.0;
        _processingStatus = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to process soft copies: $e',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showSoftCopiesSuccessDialog(String downloadUrl) {
    print('Attempting to show QR dialog...');

    // Ensure we're not in a processing state when showing dialog
    setState(() {
      _isProcessingSoftCopies = false;
      _processingProgress = 0.0;
      _processingStatus = '';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        print('Dialog builder called');
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Soft Copies Ready!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan QR below to download your soft copies, it will be available for 8 hours.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // QR Code with fixed size
                Container(
                  width: 240,
                  height: 240,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: downloadUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorStateBuilder: (context, error) {
                      print('QR Code error: $error');
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'QR generation failed',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // URL display (as backup)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: SelectableText(
                    downloadUrl,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          ref.read(photoProvider.notifier).clearAllPhotos();
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Start Over',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      print('Dialog closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(0xFF740000).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Action',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'SpaceMono',
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Print button
            Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: (widget.isPrinting || _isProcessingSoftCopies)
                    ? null
                    : () => widget.onPrint(_copies),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isPrinting
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  foregroundColor: widget.isPrinting
                      ? Color(0xFF740000).withOpacity(0.5)
                      : Color(0xFF740000),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: widget.isPrinting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              color: Color(0xFF740000).withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            'Printing...',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print_rounded, size: 48),
                          const SizedBox(width: 20),
                          Text(
                            'Print Photos',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Number of copies
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xFF740000).withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Number of Copies',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              (widget.isPrinting ||
                                  _isProcessingSoftCopies ||
                                  _copies <= 1)
                              ? Color(0xFF740000).withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color:
                                (widget.isPrinting ||
                                    _isProcessingSoftCopies ||
                                    _copies <= 1)
                                ? Colors.white.withOpacity(0.5)
                                : Color(0xFF740000),
                          ),
                          onPressed:
                              (widget.isPrinting ||
                                  _isProcessingSoftCopies ||
                                  _copies <= 1)
                              ? null
                              : () => setState(() => _copies--),
                          iconSize: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_copies',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: (widget.isPrinting || _isProcessingSoftCopies)
                              ? Color(0xFF740000).withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color:
                                (widget.isPrinting || _isProcessingSoftCopies)
                                ? Colors.white.withOpacity(0.5)
                                : Color(0xFF740000),
                          ),
                          onPressed:
                              (widget.isPrinting || _isProcessingSoftCopies)
                              ? null
                              : () => setState(() => _copies++),
                          iconSize: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Split strips toggle
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xFF740000).withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split into Strips',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontFamily: 'SpaceMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prints two identical strips (requires cutter)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontFamily: 'SpaceMono',
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: widget.splitStrips,
                    onChanged: (widget.isPrinting || _isProcessingSoftCopies)
                        ? null
                        : widget.onSplitStripsChanged,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.5),
                    inactiveThumbColor: Colors.white.withOpacity(0.7),
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),

            // Soft copies button with progress
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: _isProcessingSoftCopies ? 160 : 100,
              ),
              margin: const EdgeInsets.only(bottom: 24),
              child: OutlinedButton(
                onPressed: (widget.isPrinting || _isProcessingSoftCopies)
                    ? null
                    : _handleSoftCopies,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF740000).withOpacity(0.7),
                  side: BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isProcessingSoftCopies
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    value: _processingProgress,
                                    strokeWidth: 4,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Text(
                                _processingStatus,
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_processingProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Get Soft Copies',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const Spacer(),

            // Start over button
            Container(
              width: double.infinity,
              height: 100,
              child: TextButton(
                onPressed: (widget.isPrinting || _isProcessingSoftCopies)
                    ? null
                    : () {
                        ref.read(photoProvider.notifier).clearAllPhotos();
                        context.go('/');
                      },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF740000).withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 36,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Start Over',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
