import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

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
              case FilterConstants.vintageFilterName:
                filteredImage = FilterConstants.applyVintageFilter(
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

    setState(() {
      _isApplyingFilter = true;
    });

    try {
      final photoNotifier = ref.read(photoProvider.notifier);

      switch (_selectedFilter) {
        case FilterConstants.vintageFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyVintageFilter);
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating preview...',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we apply the filter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_previewImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a filter to see preview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Photo ${_currentCarouselIndex + 1} of ${_previewImages.length}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
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

              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Header with back button and title
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => context.go('/classic/capture'),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply Filters',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a filter to enhance your photos',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Skip button
                        Container(
                          width: 200,
                          height: 60,
                          child: OutlinedButton(
                            onPressed: () => context.go('/classic/organize'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2,
                              ),
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
                                  Text(
                                    'Choose Filter',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Filter options
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: FilterConstants
                                          .availableFilters
                                          .length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final filterName = FilterConstants
                                            .availableFilters[index];
                                        final isSelected =
                                            _selectedFilter == filterName;

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(20),
                                            leading: Radio<String>(
                                              value: filterName,
                                              groupValue: _selectedFilter,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedFilter = value;
                                                });
                                                if (value != null) {
                                                  _generateFilterPreview(value);
                                                }
                                              },
                                            ),
                                            title: Text(
                                              filterName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : null,
                                                  ),
                                            ),
                                            subtitle: Text(
                                              _getFilterDescription(filterName),
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
                                            onTap: () {
                                              setState(() {
                                                _selectedFilter = filterName;
                                              });
                                              _generateFilterPreview(
                                                filterName,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Apply button
                                  Container(
                                    width: double.infinity,
                                    height: 80,
                                    child: ElevatedButton(
                                      onPressed: _isApplyingFilter
                                          ? null
                                          : _applySelectedFilter,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: _isApplyingFilter
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
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary,
                                                      ),
                                                ),
                                                const SizedBox(width: 20),
                                                Text(
                                                  'Applying Filter...',
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
                                                Icon(
                                                  Icons.auto_fix_high_rounded,
                                                  size: 32,
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  _selectedFilter != null
                                                      ? 'Apply $_selectedFilter'
                                                      : 'Select a Filter',
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

                          const SizedBox(width: 32),

                          // Right panel - Photo preview
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
                                  Text(
                                    'Preview',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
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
                ),
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
                      onPressed: () => context.go('/classic/organize'),
                      child: Text(
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

  String _getFilterDescription(String filterName) {
    switch (filterName) {
      case 'No Filter':
        return 'Keep your photos as they are';
      case FilterConstants.vintageFilterName:
        return 'Add a classic vintage look with warm tones';
      default:
        return 'Apply this filter to your photos';
    }
  }
}
