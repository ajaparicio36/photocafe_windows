import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/services/soft_copies_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrintActionPanel extends ConsumerStatefulWidget {
  final bool isPrinting;
  final bool splitStrips;
  final ValueChanged<bool> onSplitStripsChanged;
  final VoidCallback onPrint;

  const PrintActionPanel({
    super.key,
    required this.isPrinting,
    required this.splitStrips,
    required this.onSplitStripsChanged,
    required this.onPrint,
  });

  @override
  ConsumerState<PrintActionPanel> createState() => _PrintActionPanelState();
}

class _PrintActionPanelState extends ConsumerState<PrintActionPanel> {
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

      // Step 2: Process video with VHS filter
      String? processedVideoPath;
      final photoState = ref.read(photoProvider).value;

      if (photoState?.videoPath != null) {
        setState(() {
          _processingStatus = 'Applying VHS filter to video...';
        });

        try {
          processedVideoPath = await photoNotifier.processVideoWithVHSFilter(
            onProgress: (progress) {
              setState(() {
                _processingProgress = 0.1 + (progress * 0.4); // 0.1 to 0.5
              });
            },
          );
          print('Video processing completed: $processedVideoPath');
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
                    color: Theme.of(context).colorScheme.primary,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Choose Action',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                  : widget.onPrint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          'Printing...',
                          style: TextStyle(
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Split strips toggle
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prints two identical strips (requires cutter)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
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
                ),
              ],
            ),
          ),

          // Soft copies button with progress - Fixed height constraints
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
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: Text(
                              _processingStatus,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 40),
                        const SizedBox(width: 16),
                        Text(
                          'Get Soft Copies',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 36,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Start Over',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
}
