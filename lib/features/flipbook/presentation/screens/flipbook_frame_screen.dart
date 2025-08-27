import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/frames/flipbook_frame_factory.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookFrameScreen extends ConsumerStatefulWidget {
  const FlipbookFrameScreen({super.key});

  @override
  ConsumerState<FlipbookFrameScreen> createState() =>
      _FlipbookFrameScreenState();
}

class _FlipbookFrameScreenState extends ConsumerState<FlipbookFrameScreen> {
  String _selectedFrame = 'standard_frame'; // Default to standard frame
  bool _isGeneratingPdf = false;

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final videoState = ref.read(videoProvider).value;
      if (videoState == null || videoState.frames.isEmpty) {
        throw Exception('No frames available to generate PDF.');
      }

      // Get the selected frame definition
      final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
        (frame) => frame.id == _selectedFrame,
        orElse: () => FlipbookFrameConstants.availableFrames.first,
      );

      // Use the frame factory to generate PDF
      final pdfBytes = await FlipbookFrameFactory.generatePdfForFrame(
        frameDefinition,
        videoState.frames,
      );

      context.go('/flipbook/print', extra: pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Widget _buildFrameSelector() {
    final availableFrames = FlipbookFrameConstants.availableFrames;

    return Column(
      children: availableFrames.map((frame) {
        final isSelected = _selectedFrame == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFFBEE)
                : const Color(0xFF5A1908),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFFFBEE)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF76220B)
                        : const Color(0xFFFFFBEE),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: const Color(0xFF76220B),
                      )
                    : null,
              ),
              title: Text(
                frame.name,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF76220B)
                      : const Color(0xFFFFFBEE),
                ),
              ),
              subtitle: Text(
                frame.description,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFF76220B).withOpacity(0.8)
                      : const Color(0xFFFFFBEE).withOpacity(0.8),
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedFrame = frame.id;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFramePreview() {
    // Get the selected frame definition
    final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FlipbookFrameConstants.availableFrames.first,
    );

    // Use the frame factory to create the preview widget with a key to force rebuilds
    return Container(
      key: ValueKey('preview_container_$_selectedFrame'),
      child: FlipbookFrameFactory.createFrameWidget(frameDefinition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF76220B)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
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
                      onPressed: () => context.go('/flipbook/filter'),
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
                        'Apply Frame',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFBEE),
                        ),
                      ),
                      Text(
                        videoState.hasValue &&
                                videoState.value!.frames.isNotEmpty
                            ? 'Choose a frame for your ${videoState.value!.frames.length}-frame flipbook'
                            : 'Choose a frame for your flipbook pages',
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
                    // Left Panel: Frame Selection
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
                              'Select Frame',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFFBEE),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Dynamic frame selector
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildFrameSelector(),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Print button
                            Container(
                              width: double.infinity,
                              height: 80,
                              child: ElevatedButton(
                                onPressed: _isGeneratingPdf
                                    ? null
                                    : _proceedToPrint,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isGeneratingPdf
                                      ? const Color(0xFFFFFBEE).withOpacity(0.5)
                                      : const Color(0xFFFFFBEE),
                                  foregroundColor: _isGeneratingPdf
                                      ? const Color(0xFF76220B).withOpacity(0.5)
                                      : const Color(0xFF76220B),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  shadowColor: Colors.transparent,
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
                                              color: const Color(
                                                0xFF76220B,
                                              ).withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            'Generating PDF...',
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
                                            'Proceed to Print',
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

                    // Right Panel: Preview
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
                                key: ValueKey(
                                  'preview_wrapper_$_selectedFrame',
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFFFFBEE),
                                    width: 4,
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: videoState.when(
                                    data: (state) => state.frames.isNotEmpty
                                        ? _buildFramePreview()
                                        : Container(
                                            color: Colors.black,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .photo_library_outlined,
                                                    size: 48,
                                                    color: const Color(
                                                      0xFFFFFBEE,
                                                    ).withOpacity(0.4),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No frames to preview',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'LeagueSpartan',
                                                      color: const Color(
                                                        0xFFFFFBEE,
                                                      ).withOpacity(0.6),
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    loading: () => Container(
                                      color: Colors.black,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              color: const Color(0xFFFFFBEE),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Loading frames...',
                                              style: TextStyle(
                                                fontFamily: 'LeagueSpartan',
                                                color: const Color(0xFFFFFBEE),
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    error: (e, s) => Container(
                                      color: Colors.black,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              size: 48,
                                              color: Colors.red.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Error: $e',
                                              style: TextStyle(
                                                fontFamily: 'LeagueSpartan',
                                                color: const Color(0xFFFFFBEE),
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
