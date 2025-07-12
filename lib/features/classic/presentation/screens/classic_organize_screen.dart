import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

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

    final pdf = pw.Document();

    // Sort photos by index to ensure correct order
    final sortedPhotos = List.from(photoState.photos)
      ..sort((a, b) => a.index.compareTo(b.index));

    // Load photo images
    final photoImages = <pw.MemoryImage>[];
    for (final photo in sortedPhotos) {
      final file = File(photo.imagePath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        photoImages.add(pw.MemoryImage(imageBytes));
      }
    }

    // Create PDF page with frame layout
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2, color: PdfColors.black),
            ),
            child: pw.Row(
              children: [
                // Left column
                pw.Expanded(
                  child: pw.Column(
                    children: List.generate(4, (i) {
                      return pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey),
                          ),
                          child: photoImages.length > i
                              ? pw.Image(photoImages[i], fit: pw.BoxFit.cover)
                              : pw.Container(),
                        ),
                      );
                    }),
                  ),
                ),
                // Right column (duplicate)
                pw.Expanded(
                  child: pw.Column(
                    children: List.generate(4, (i) {
                      return pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey),
                          ),
                          child: photoImages.length > i
                              ? pw.Image(photoImages[i], fit: pw.BoxFit.cover)
                              : pw.Container(),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoStateAsync = ref.watch(photoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organize Photos'),
        actions: [
          if (!_isGeneratingPdf)
            TextButton(
              onPressed: _proceedToPrint,
              child: const Text('Continue to Print'),
            ),
        ],
      ),
      body: photoStateAsync.when(
        data: (photoState) {
          if (photoState.photos.isEmpty) {
            return const Center(child: Text('No photos available'));
          }

          // Sort photos by index for display
          final sortedPhotos = List.from(photoState.photos)
            ..sort((a, b) => a.index.compareTo(b.index));

          return Column(
            children: [
              // Frame selection
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Frame:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: _selectedFrame == 'frame_one'
                          ? Colors.blue.shade100
                          : null,
                      child: ListTile(
                        title: const Text('Classic Frame'),
                        subtitle: const Text(
                          '4 photos side by side, duplicated',
                        ),
                        leading: Radio<String>(
                          value: 'frame_one',
                          groupValue: _selectedFrame,
                          onChanged: (value) {
                            setState(() {
                              _selectedFrame = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Photo organization section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drag to Reorder Photos:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Draggable photo list
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: sortedPhotos.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }

                            // Get the indices to swap
                            final photoA = sortedPhotos[oldIndex];
                            final photoB = sortedPhotos[newIndex];

                            // Swap the indices in the photo notifier
                            await ref
                                .read(photoProvider.notifier)
                                .switchPhotoOrder(photoA.index, photoB.index);
                          },
                          itemBuilder: (context, index) {
                            final photo = sortedPhotos[index];
                            return Card(
                              key: ValueKey(photo.index),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(photo.imagePath)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Text('Photo ${index + 1}'),
                                subtitle: Text('Position: ${photo.index}'),
                                trailing: const Icon(Icons.drag_handle),
                              ),
                            );
                          },
                        ),
                      ),

                      // PDF Preview
                      const SizedBox(height: 16),
                      const Text(
                        'Preview:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PdfPreview(
                          build: (format) => _generatePdf(),
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: false,
                          allowSharing: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isGeneratingPdf ? null : _proceedToPrint,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isGeneratingPdf
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Generating...'),
                                ],
                              )
                            : const Text('Proceed to Print'),
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
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => context.go('/classic/print'),
                child: const Text('Skip to Print'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
