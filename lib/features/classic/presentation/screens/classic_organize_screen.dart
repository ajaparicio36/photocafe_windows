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

class ClassicOrganizeScreen extends ConsumerStatefulWidget {
  const ClassicOrganizeScreen({super.key});

  @override
  ConsumerState<ClassicOrganizeScreen> createState() =>
      _ClassicOrganizeScreenState();
}

class _ClassicOrganizeScreenState extends ConsumerState<ClassicOrganizeScreen> {
  String _selectedFrame = 'frame_one'; // Default to classic frame
  bool _isGeneratingPdf = false;

  // Get available frames for current capture count
  List<FrameDefinition> get _availableFrames {
    final photoState = ref.read(photoProvider).value;
    if (photoState == null) return [];

    final currentLayout = photoState.captureCount == 2
        ? FrameLayoutType.twoPhotos
        : FrameLayoutType.fourPhotos;

    return FrameConstants.availableFrames
        .where((frame) => frame.supportedLayouts.contains(currentLayout))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Set default frame based on capture count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final photoState = ref.read(photoProvider).value;
      if (photoState?.captureCount == 2) {
        setState(() {
          _selectedFrame =
              '2by2_frame_one'; // Default to 2x2 frame for 2-photo mode
        });
      } else if (photoState?.captureCount == 4) {
        setState(() {
          _selectedFrame =
              '4by4_frame_one'; // Default to 4x4 frame for 4-photo mode
        });
      }
    });
  }

  Future<Uint8List> _generatePdf() async {
    final photoState = ref.read(photoProvider).value;
    if (photoState == null || photoState.photos.isEmpty) {
      throw Exception('No photos available');
    }

    // Get the selected frame definition
    final frameDefinition = FrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FrameConstants.availableFrames.first,
    );

    // Use the frame factory to generate PDF
    return await FrameFactory.generatePdfForFrame(
      frameDefinition,
      photoState.photos,
      photoState.captureCount,
    );
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

  Widget _buildFrameSelector(PhotoState photoState) {
    final availableFrames = _availableFrames;

    if (availableFrames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No frames available for ${photoState.captureCount} photos',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: frame.id,
                groupValue: _selectedFrame,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFrame = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frame.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      frame.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${photoState.captureCount} photos in ${frame.name.toLowerCase()}',
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
        );
      }).toList(),
    );
  }

  Widget _buildFramePreview(PhotoState photoState) {
    // Get the selected frame definition
    final frameDefinition = FrameConstants.availableFrames.firstWhere(
      (frame) => frame.id == _selectedFrame,
      orElse: () => FrameConstants.availableFrames.first,
    );

    // Use the frame factory to create the preview widget
    return FrameFactory.createFrameWidget(frameDefinition);
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
                            // Frame selection header
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

                            // Dynamic frame selector
                            _buildFrameSelector(photoState),

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
                                  child: _buildFramePreview(photoState),
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
