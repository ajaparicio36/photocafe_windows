import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/filter/filter_selection_panel.dart';

class ClassicFilterScreen extends ConsumerStatefulWidget {
  const ClassicFilterScreen({super.key});

  @override
  ConsumerState<ClassicFilterScreen> createState() =>
      _ClassicFilterScreenState();
}

class _ClassicFilterScreenState extends ConsumerState<ClassicFilterScreen> {
  String? _selectedFilter;
  bool _isApplyingFilter = false;
  bool _isGeneratingPreview = false;
  List<Uint8List> _previewImages = [];
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set "No Filter" as default selection
    _selectedFilter = FilterConstants.availableFilters.first;
    _generateFilterPreview(_selectedFilter!);
  }

  Future<void> _generateFilterPreview(String filterName) async {
    setState(() {
      _isGeneratingPreview = true;
      _previewImages = [];
    });

    try {
      final photoState = ref.read(photoProvider).value;
      if (photoState == null || photoState.photos.isEmpty) return;

      final previewImages = <Uint8List>[];

      for (final photo in photoState.photos) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);

          if (originalImage != null) {
            img.Image filteredImage;
            switch (filterName) {
              case FilterConstants.noFilterName:
                filteredImage = originalImage;
                break;
              case FilterConstants.vintageFilterName:
                filteredImage = FilterConstants.applyVintageFilter(
                  originalImage,
                );
                break;
              case FilterConstants.hdrFilterName:
                filteredImage = FilterConstants.applyHdrFilter(originalImage);
                break;
              case FilterConstants.matteFilterName:
                filteredImage = FilterConstants.applyMatteFilter(originalImage);
                break;
              case FilterConstants.lomoFilterName:
                filteredImage = FilterConstants.applyLomoFilter(originalImage);
                break;
              case FilterConstants.pastelFilterName:
                filteredImage = FilterConstants.applyPastelFilter(
                  originalImage,
                );
                break;
              case FilterConstants.duotoneFilterName:
                filteredImage = FilterConstants.applyDuotoneFilter(
                  originalImage,
                );
                break;
              case FilterConstants.grittyFilterName:
                filteredImage = FilterConstants.applyGrittyFilter(
                  originalImage,
                );
                break;
              case FilterConstants.vscoA6FilterName:
                filteredImage = FilterConstants.applyVscoA6Filter(
                  originalImage,
                );
                break;
              case FilterConstants.blackWhiteFilterName:
                filteredImage = FilterConstants.applyMonoFilter(originalImage);
                break;
              case FilterConstants.cinematicFilterName:
                filteredImage = FilterConstants.applyCinematicFilter(
                  originalImage,
                );
                break;
              default:
                filteredImage = originalImage;
            }

            final filteredBytes = img.encodeJpg(filteredImage);
            previewImages.add(filteredBytes);
          }
        }
      }

      setState(() {
        _previewImages = previewImages;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating preview: $e')));
    } finally {
      setState(() {
        _isGeneratingPreview = false;
      });
    }
  }

  Future<void> _applySelectedFilter() async {
    if (_selectedFilter == null) return;

    // If "No Filter" is selected, just navigate
    if (_selectedFilter == FilterConstants.noFilterName) {
      context.go('/classic/organize');
      return;
    }

    setState(() {
      _isApplyingFilter = true;
    });

    try {
      final photoNotifier = ref.read(photoProvider.notifier);

      switch (_selectedFilter) {
        case FilterConstants.vintageFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyVintageFilter);
          break;
        case FilterConstants.hdrFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyHdrFilter);
          break;
        case FilterConstants.matteFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyMatteFilter);
          break;
        case FilterConstants.lomoFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyLomoFilter);
          break;
        case FilterConstants.pastelFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyPastelFilter);
          break;
        case FilterConstants.duotoneFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyDuotoneFilter);
          break;
        case FilterConstants.grittyFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyGrittyFilter);
          break;
        case FilterConstants.vscoA6FilterName:
          await photoNotifier.applyFilters(FilterConstants.applyVscoA6Filter);
          break;
        case FilterConstants.blackWhiteFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyMonoFilter);
          break;
        case FilterConstants.cinematicFilterName:
          await photoNotifier.applyFilters(
            FilterConstants.applyCinematicFilter,
          );
          break;
        default:
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Filter applied successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      context.go('/classic/organize');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying filter: $e')));
    } finally {
      setState(() {
        _isApplyingFilter = false;
      });
    }
  }

  Widget _buildPreviewCarousel() {
    if (_isGeneratingPreview) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF76220B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEE).withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFFFFFBEE),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating preview...',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFFBEE),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we apply the filter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFFFFBEE).withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_previewImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF76220B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: const Color(0xFFFFFBEE).withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a filter to see preview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: const Color(0xFFFFFBEE).withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Carousel
        Expanded(
          child: CarouselSlider.builder(
            itemCount: _previewImages.length,
            itemBuilder: (context, index, realIndex) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.memory(
                    _previewImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: double.infinity,
              enlargeCenterPage: true,
              enableInfiniteScroll: _previewImages.length > 1,
              viewportFraction: 0.75,
              autoPlay: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Photo indicator and navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_rounded,
                    size: 24,
                    color: const Color(0xFF76220B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Photo ${_currentCarouselIndex + 1} of ${_previewImages.length}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: const Color(0xFF76220B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoStateAsync = ref.watch(photoProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF76220B)),
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
                        color: const Color(0xFFFFFBEE).withOpacity(0.4),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No photos available',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: 36,
                              color: const Color(0xFFFFFBEE),
                            ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () => context.go('/classic/capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEE),
                            foregroundColor: const Color(0xFF76220B),
                          ),
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

              return Column(
                children: [
                  // Header with back and skip buttons
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
                          onPressed: () => context.go('/classic/capture'),
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
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFFBEE),
                            ),
                          ),
                          Text(
                            'Choose a filter to enhance your photos',
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color(0xFFFFFBEE).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Skip button
                      Container(
                        width: 200,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => context.go('/classic/organize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEE),
                            foregroundColor: const Color(0xFF76220B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Skip Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Main content area
                  Expanded(
                    child: Row(
                      children: [
                        // Left panel - Filter selection
                        Expanded(
                          flex: 2,
                          child: FilterSelectionPanel(
                            selectedFilter: _selectedFilter,
                            isApplyingFilter: _isApplyingFilter,
                            onFilterSelected: (filterName) {
                              setState(() {
                                _selectedFilter = filterName;
                              });
                              _generateFilterPreview(filterName);
                            },
                            onApplyFilter: _applySelectedFilter,
                          ),
                        ),

                        const SizedBox(width: 32),

                        // Right panel - Photo preview
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFFBEE),
                                      ),
                                ),
                                const SizedBox(height: 24),
                                Expanded(child: _buildPreviewCarousel()),
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
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFFBEE)),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 80, color: Color(0xFFFFFBEE)),
                  const SizedBox(height: 24),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Color(0xFFFFFBEE)),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 300,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => context.go('/classic/organize'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBEE),
                        foregroundColor: const Color(0xFF76220B),
                      ),
                      child: const Text(
                        'Skip to Organize',
                        style: TextStyle(
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
}
