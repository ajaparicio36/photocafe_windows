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
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_one.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/organize/photo_organization_panel.dart';

class ClassicOrganizeScreen extends ConsumerStatefulWidget {
  const ClassicOrganizeScreen({super.key});

  @override
  ConsumerState<ClassicOrganizeScreen> createState() =>
      _ClassicOrganizeScreenState();
}

class _ClassicOrganizeScreenState extends ConsumerState<ClassicOrganizeScreen> {
  String _selectedFrame = 'frame_one';
  bool _isGeneratingPdf = false;

  Future<Uint8List> _generatePdf() async {
    final photoState = ref.read(photoProvider).value;
    if (photoState == null || photoState.photos.isEmpty) {
      throw Exception('No photos available');
    }

    // Call the FrameOne's _generatePdf method through a helper
    return await _generateFrameOnePdf(photoState.photos);
  }

  Future<Uint8List> _generateFrameOnePdf(List<PhotoModel> photos) async {
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Images below (left column)
              for (int i = 0; i < 4; i++)
                pw.Positioned(
                  left: 13,
                  top: 14 + i * 92.5,
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
              for (int i = 0; i < 4; i++)
                pw.Positioned(
                  left: 158,
                  top: 14 + i * 92.5,
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
                                          '4 photos in a strip layout with decorative frame',
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
                                      ? const FrameOne()
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
}
