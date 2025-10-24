import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
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
  String _selectedFrame = 'standard_frame';
  bool _isGeneratingPdf = false;
  bool _isPrinting = false;

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final videoState = ref.read(videoProvider).value;
      if (videoState == null || videoState.frames.isEmpty) {
        throw Exception('No frames available to generate PDF.');
      }

      final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
        (frame) => frame.id == _selectedFrame,
        orElse: () => FlipbookFrameConstants.availableFrames.first,
      );

      final pdfBytes = await FlipbookFrameFactory.generatePdfForFrame(
        frameDefinition,
        videoState.frames,
      );

      // Print directly instead of navigating
      await _printDocument(pdfBytes);
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

  Future<void> _printDocument(Uint8List pdfBytes) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final printerNotifier = ref.read(printerProvider.notifier);
      await printerNotifier.printPdfBytesForVideo(pdfBytes);

      // Clear video state before navigating back to home
      if (mounted) {
        await ref.read(videoProvider.notifier).clearVideo();
        context.go('/');
      }
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

  Widget _buildFrameSelector() {
    final availableFrames = FlipbookFrameConstants.availableFrames;

    return Column(
      children: availableFrames.map((frame) {
        final isSelected = _selectedFrame == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
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
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Color(0xFF740000) : Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: Color(0xFF740000))
                    : null,
              ),
              title: Text(
                frame.name,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Color(0xFF740000) : Colors.white,
                ),
              ),
              subtitle: Text(
                frame.description,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 16,
                  color: isSelected
                      ? Color(0xFF740000).withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
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
    final frameDefinition = FlipbookFrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FlipbookFrameConstants.availableFrames.first,
    );

    // Rotate the preview 90° for landscape display using RotatedBox
    // RotatedBox rotates in quarter turns: 1 = 90°, 2 = 180°, 3 = 270°
    return RotatedBox(
      quarterTurns: 3, // 270 degrees clockwise = -90 degrees counterclockwise
      child: FlipbookFrameFactory.createFrameWidget(frameDefinition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/design/background.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: videoState.when(
            data: (state) {
              if (state.frames.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 100,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No frames available',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () => context.go('/flipbook/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF740000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Record Video',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
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

              return Column(
                children: [
                  // Header
                  Row(
                    children: [
                      // Back button
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            color: Color(0xFF740000),
                            size: 28,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Image.asset(
                        'assets/design/frames/frames_title.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      SizedBox(width: 60),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Main content
                  Expanded(
                    child: Row(
                      children: [
                        // Left panel - Frame selection
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SELECT FRAME',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildFrameSelector(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Proceed button
                                Container(
                                  width: double.infinity,
                                  height: 80,
                                  child: ElevatedButton(
                                    onPressed: _isGeneratingPdf || _isPrinting
                                        ? null
                                        : _proceedToPrint,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _isGeneratingPdf || _isPrinting
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.white,
                                      foregroundColor:
                                          _isGeneratingPdf || _isPrinting
                                          ? Color(0xFF740000).withOpacity(0.5)
                                          : Color(0xFF740000),
                                      elevation: 0,
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
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: Color(
                                                        0xFF740000,
                                                      ).withOpacity(0.5),
                                                    ),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                'Generating...',
                                                style: TextStyle(
                                                  fontFamily: 'SpaceMono',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : _isPrinting
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 32,
                                                height: 32,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: Color(
                                                        0xFF740000,
                                                      ).withOpacity(0.5),
                                                    ),
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                'Printing...',
                                                style: TextStyle(
                                                  fontFamily: 'SpaceMono',
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
                                              Icon(
                                                Icons.print_rounded,
                                                size: 32,
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                'Proceed to Print',
                                                style: TextStyle(
                                                  fontFamily: 'SpaceMono',
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
                        // Right panel - Preview
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              // Background
                              Positioned.fill(
                                left: 100,
                                right: 60,
                                bottom: 300,
                                child: Image.asset(
                                  'assets/design/flipbook-filters/filters_preview.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 70,
                                  right: 30,
                                  top: 70,
                                  bottom: 320,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PREVIEW',
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 50),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          // RotatedBox properly swaps width/height during rotation
                                          // So we want the final result to be 6:4 (landscape)
                                          final maxWidth = constraints.maxWidth;
                                          final maxHeight =
                                              constraints.maxHeight;

                                          double width, height;
                                          const targetAspectRatio =
                                              6 / 4; // Landscape ratio

                                          if (maxWidth / maxHeight >
                                              targetAspectRatio) {
                                            // Height constrained
                                            height = maxHeight;
                                            width = height * targetAspectRatio;
                                          } else {
                                            // Width constrained
                                            width = maxWidth;
                                            height = width / targetAspectRatio;
                                          }

                                          return Center(
                                            child: SizedBox(
                                              width: width,
                                              height: height,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: _buildFramePreview(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    'Error: $error',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
