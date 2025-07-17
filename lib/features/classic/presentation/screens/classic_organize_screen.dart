import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:printing/printing.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_one.dart'
    as frames;
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/organize/photo_organization_panel.dart';
import 'package:photocafe_windows/features/photos/domain/services/soft_copies_service.dart';

class ClassicOrganizeScreen extends ConsumerStatefulWidget {
  const ClassicOrganizeScreen({super.key});

  @override
  ConsumerState<ClassicOrganizeScreen> createState() =>
      _ClassicOrganizeScreenState();
}

class _ClassicOrganizeScreenState extends ConsumerState<ClassicOrganizeScreen> {
  String _selectedFrame = 'frame_one';
  bool _isGeneratingPdf = false;
  final SoftCopiesService _softCopiesService = SoftCopiesService();
  bool _isUploadingSoftCopies = false;
  String? _archiveUrl;

  Future<Uint8List> _generatePdf() async {
    final photoState = ref.read(photoProvider).value;
    if (photoState == null || photoState.photos.isEmpty) {
      throw Exception('No photos available');
    }

    // Call the FrameOne's _generatePdf method through a helper
    return await _generateFrameOnePdf(
      photoState.photos,
      photoState.captureCount,
    );
  }

  Future<Uint8List> _generateFrameOnePdf(
    List<PhotoModel> photos,
    int captureCount,
  ) async {
    // This replicates the FrameOne._generatePdf method
    final pdf = pw.Document();

    // Load the frame background
    final frameImageBytes = await rootBundle.load('assets/frames/frame1.png');
    final frameImage = pw.MemoryImage(frameImageBytes.buffer.asUint8List());

    // Sort photos by index to ensure correct order
    final sortedPhotos = List.from(photos)
      ..sort((a, b) => a.index.compareTo(b.index));

    // Load captured photo images
    final photoImages = <pw.MemoryImage>[];
    for (final photo in sortedPhotos) {
      final file = File(photo.imagePath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        photoImages.add(pw.MemoryImage(imageBytes));
      }
    }

    // Fallback to test image if no photos available
    pw.MemoryImage? testImage;
    if (photoImages.isEmpty) {
      try {
        final testImageBytes = await rootBundle.load('assets/frames/test.jpg');
        testImage = pw.MemoryImage(testImageBytes.buffer.asUint8List());
      } catch (e) {
        print('Test image not found: $e');
      }
    }

    final int photoCount = captureCount == 2 ? 2 : 4;
    final double topOffset = captureCount == 2 ? 100 : 14;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Images below (left column)
              for (int i = 0; i < photoCount; i++)
                pw.Positioned(
                  left: 13,
                  top: topOffset + i * 92.5,
                  child: pw.Container(
                    width: 125,
                    height: 78,
                    child: photoImages.length > i
                        ? pw.Image(
                            photoImages[i],
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : testImage != null
                        ? pw.Image(
                            testImage,
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : pw.Container(
                            color: PdfColors.grey300,
                            child: pw.Center(
                              child: pw.Text(
                                'Photo ${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              // Images below (right column - duplicates)
              for (int i = 0; i < photoCount; i++)
                pw.Positioned(
                  left: 158,
                  top: topOffset + i * 92.5,
                  child: pw.Container(
                    width: 125,
                    height: 78,
                    child: photoImages.length > i
                        ? pw.Image(
                            photoImages[i],
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : testImage != null
                        ? pw.Image(
                            testImage,
                            fit: pw.BoxFit.cover,
                            width: 125,
                            height: 78,
                          )
                        : pw.Container(
                            color: PdfColors.grey300,
                            child: pw.Center(
                              child: pw.Text(
                                'Photo ${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),

              // Frame overlay on top
              pw.Positioned.fill(
                child: pw.Image(frameImage, fit: pw.BoxFit.fill),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await _generatePdf();
      context.go('/classic/print', extra: pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  Future<void> _uploadSoftCopies() async {
    setState(() {
      _isUploadingSoftCopies = true;
    });

    try {
      // Get all media files
      final mediaFiles = await ref
          .read(photoProvider.notifier)
          .getAllMediaFiles();

      // Get processed video if available
      final processedVideo = await ref
          .read(photoProvider.notifier)
          .getProcessedVideo();
      final processedVideoPath = processedVideo?.path;

      if (mediaFiles.isEmpty) {
        throw Exception('No media files to upload');
      }

      // Upload with progress tracking
      final result = await _softCopiesService.uploadMediaFiles(
        mediaFiles: mediaFiles,
        processedVideoPath: processedVideoPath,
        onProgress: (progress) {
          // You can add a progress indicator here if needed
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (result.success) {
        setState(() {
          _archiveUrl = result.downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Soft copies uploaded successfully!\nArchive: ${result.archiveId}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => _showArchiveDialog(),
            ),
          ),
        );
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Soft copies upload failed: $e',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isUploadingSoftCopies = false;
      });
    }
  }

  void _showArchiveDialog() {
    if (_archiveUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_done_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text('Soft Copies Ready'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your photos and video have been uploaded to the cloud.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _archiveUrl!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _archiveUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('URL copied to clipboard')),
                      );
                    },
                    icon: Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Open URL in browser if possible
              Navigator.of(context).pop();
            },
            child: Text('View Archive'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoStateAsync = ref.watch(photoProvider);

    return ScreenContainer(
      child: photoStateAsync.when(
        data: (photoState) {
          if (photoState.photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 100,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'No photos available',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 300,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => context.go('/classic/capture'),
                      child: Text(
                        'Take Photos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // List<PhotoModel> sortedPhotos type
          final List<PhotoModel> sortedPhotos = List.from(photoState.photos)
            ..sort((a, b) => a.index.compareTo(b.index));

          return Column(
            children: [
              // Header
              ScreenHeader(
                title: 'Organize & Frame',
                subtitle: 'Arrange your photos and choose a frame',
                backRoute: '/classic/filter',
              ),

              const SizedBox(height: 40),

              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Left panel - Photo organization
                    Expanded(
                      flex: 2,
                      child: PhotoOrganizationPanel(
                        sortedPhotos: sortedPhotos,
                        onReorder: (oldIndex, newIndex) async {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }

                          final items = List<PhotoModel>.from(sortedPhotos);
                          final item = items.removeAt(oldIndex);
                          items.insert(newIndex, item);

                          await ref
                              .read(photoProvider.notifier)
                              .reorderPhotos(items);
                        },
                      ),
                    ),

                    const SizedBox(width: 32),

                    // Right panel - Frame selection and preview
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
                            // Frame selection
                            Row(
                              children: [
                                Icon(
                                  Icons.crop_free_rounded,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Select Frame',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _selectedFrame == 'frame_one'
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedFrame == 'frame_one'
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  width: _selectedFrame == 'frame_one' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'frame_one',
                                    groupValue: _selectedFrame,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFrame = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Classic Frame',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color:
                                                    _selectedFrame ==
                                                        'frame_one'
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : null,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'A decorative strip layout for your photos.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${photoState.captureCount} photos in a strip layout with decorative frame',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Frame Preview
                            Text(
                              'Preview',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: _selectedFrame == 'frame_one'
                                      ? const frames.FrameOne()
                                      : PdfPreview(
                                          build: (format) => _generatePdf(),
                                          canChangePageFormat: false,
                                          canDebug: false,
                                          allowPrinting: false,
                                          allowSharing: false,
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Proceed button
                            Container(
                              width: double.infinity,
                              height: 80,
                              child: ElevatedButton(
                                onPressed: _isGeneratingPdf
                                    ? null
                                    : _proceedToPrint,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isGeneratingPdf
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            'Generating...',
                                            style: TextStyle(
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
                                            'Proceed to Print',
                                            style: TextStyle(
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
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text('Error: $error'),
              const SizedBox(height: 32),
              Container(
                width: 300,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => context.go('/classic/print'),
                  child: Text(
                    'Skip to Print',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel(photoState) {
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
          // Frame selection
          Row(
            children: [
              Icon(
                Icons.crop_free_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Select Frame',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _selectedFrame == 'frame_one'
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedFrame == 'frame_one'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: _selectedFrame == 'frame_one' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: 'frame_one',
                  groupValue: _selectedFrame,
                  onChanged: (value) {
                    setState(() {
                      _selectedFrame = value!;
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classic Frame',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: _selectedFrame == 'frame_one'
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A decorative strip layout for your photos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${photoState.captureCount} photos in a strip layout with decorative frame',
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
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Soft Copies Section
          Row(
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Soft Copies',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Upload photos and video to the cloud for easy sharing and downloading.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: _isUploadingSoftCopies ? null : _uploadSoftCopies,
              icon: _isUploadingSoftCopies
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Icon(Icons.cloud_upload_rounded, size: 32),
              label: Text(
                _isUploadingSoftCopies ? 'Uploading...' : 'Upload Soft Copies',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _archiveUrl != null
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (_archiveUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                onPressed: _showArchiveDialog,
                icon: Icon(Icons.visibility_rounded),
                label: Text(
                  'View Archive',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
