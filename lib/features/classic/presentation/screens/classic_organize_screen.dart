import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_state.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_factory.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/organize/photo_organization_panel.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class ClassicOrganizeScreen extends ConsumerStatefulWidget {
  const ClassicOrganizeScreen({super.key});

  @override
  ConsumerState<ClassicOrganizeScreen> createState() =>
      _ClassicOrganizeScreenState();
}

class _ClassicOrganizeScreenState extends ConsumerState<ClassicOrganizeScreen> {
  final ScrollController _frameSelectorController = ScrollController();
  String _selectedFrame = 'frame_one'; // Default to classic frame
  bool _isGeneratingPdf = false;

  // Get available frames for current capture count
  List<FrameDefinition> get _availableFrames {
    final printerState = ref.read(printerProvider).value;
    if (printerState == null) return [];

    final FrameLayoutType currentLayout;
    if (printerState.isLandscape) {
      currentLayout = FrameLayoutType.fourLandscapePhotos;
    } else if (printerState.layoutMode == 2) {
      currentLayout = FrameLayoutType.twoPhotos;
    } else {
      currentLayout = FrameLayoutType.fourPhotos;
    }

    return FrameConstants.availableFrames
        .where((frame) => frame.supportedLayouts.contains(currentLayout))
        .toList();
  }

  @override
  void dispose() {
    _frameSelectorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final printerState = ref.read(printerProvider).value;
      if (printerState?.isLandscape == true) {
        setState(() {
          _selectedFrame = 'landscape_frame_one';
        });
      } else if (printerState?.layoutMode == 2) {
        setState(() {
          _selectedFrame = '2by2_frame_one';
        });
      } else {
        setState(() {
          _selectedFrame = '4by4_frame_one';
        });
      }
    });
  }

  Future<Uint8List> _generatePdf() async {
    final photoState = ref.read(photoProvider).value;
    final printerState = ref.read(printerProvider).value;

    if (photoState == null || photoState.photos.isEmpty) {
      throw Exception('No photos available');
    }

    if (printerState == null) {
      throw Exception('Printer settings not available');
    }

    final frameDefinition = FrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FrameConstants.availableFrames.first,
    );

    return await FrameFactory.generatePdfForFrame(
      frameDefinition,
      photoState.photos,
      printerState.layoutMode, // Use layout mode instead of capture count
      printerState.isLandscape, // Pass isLandscape flag
    );
  }

  Future<void> _proceedToPrint() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await _generatePdf();
      final printerState = ref.read(printerProvider).value;
      final isLandscape = printerState?.isLandscape ?? false;

      context.go(
        '/classic/print',
        extra: {'pdfBytes': pdfBytes, 'isLandscape': isLandscape},
      );
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/design/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
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
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No photos available',
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
                          onPressed: () => context.go('/classic/capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF740000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Take Photos',
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

              final List<PhotoModel> sortedPhotos = List.from(photoState.photos)
                ..sort((a, b) => a.index.compareTo(b.index));

              return Column(
                children: [
                  // Header with back button and title
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
                          onPressed: () => context.go('/classic/filter'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF740000),
                            size: 28,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Title image
                      Image.asset(
                        'assets/design/frames/frames_title.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),

                      const Spacer(),

                      // Empty space for symmetry
                      SizedBox(width: 60),
                    ],
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

                        // Middle panel - Frame selection
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Frame selection header
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

                                // Dynamic frame selector
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildFrameSelector(photoState),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Proceed button
                                Container(
                                  width: double.infinity,
                                  height: 80,
                                  child: ElevatedButton(
                                    onPressed: _isGeneratingPdf
                                        ? null
                                        : _proceedToPrint,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isGeneratingPdf
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.white,
                                      foregroundColor: _isGeneratingPdf
                                          ? Color(0xFF740000).withOpacity(0.5)
                                          : Color(0xFF740000),
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

                        // Right panel - Frame preview
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              // Background image
                              Positioned.fill(
                                left: 100,
                                right: 60,
                                child: Image.asset(
                                  'assets/design/frames/frames_preview.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 70,
                                  right: 30,
                                  top: 70,
                                  bottom: 130,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Frame Preview header
                                    Text(
                                      'PREVIEW',
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 140),

                                    Expanded(
                                      child: Center(
                                        child: AspectRatio(
                                          aspectRatio: 4 / 6,
                                          child: FractionallySizedBox(
                                            widthFactor: 1.4,
                                            heightFactor: 1.35,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: _buildFramePreview(
                                                  photoState,
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
                  const SizedBox(height: 32),
                  Container(
                    width: 300,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => context.go('/classic/print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF740000),
                      ),
                      child: Text(
                        'Skip to Print',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrameSelector(PhotoState photoState) {
    final availableFrames = _availableFrames;

    if (availableFrames.isEmpty) {
      final printerState = ref.read(printerProvider).value;
      final layoutMode = printerState?.layoutMode ?? 4;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No frames available for ${layoutMode == 2 ? "2x2" : "4x4"} layout',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: availableFrames.map((frame) {
        final isSelected = _selectedFrame == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Color(0xFF740000).withOpacity(0.5),
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

  Widget _buildFramePreview(PhotoState photoState) {
    final printerState = ref.read(printerProvider).value;
    final frameDefinition = FrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FrameConstants.availableFrames.first,
    );

    final frameWidget = FrameFactory.createFrameWidget(frameDefinition);

    // Rotate preview for landscape frames (similar to flipbook)
    if (printerState?.isLandscape == true) {
      return RotatedBox(
        quarterTurns: 3, // 270 degrees clockwise = -90 degrees counterclockwise
        child: frameWidget,
      );
    }

    return frameWidget;
  }
}
