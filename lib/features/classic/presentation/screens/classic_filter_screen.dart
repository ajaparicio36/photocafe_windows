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
              // case FilterConstants.matteFilterName:
              //   filteredImage = FilterConstants.applyMatteFilter(originalImage);
              //   break;
              // case FilterConstants.vscoA6FilterName:
              //   filteredImage = FilterConstants.applyVscoA6Filter(
              //     originalImage,
              //   );
              //   break;
              case FilterConstants.blackWhiteFilterName:
                filteredImage = FilterConstants.applyMonoFilter(originalImage);
                break;
              // case FilterConstants.cinematicFilterName:
              //   filteredImage = FilterConstants.applyCinematicFilter(
              //     originalImage,
              //   );
              //   break;
              case FilterConstants.photoboothFilterName:
                filteredImage = FilterConstants.applyPhotoboothFilter(
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
        // case FilterConstants.matteFilterName:
        //   await photoNotifier.applyFilters(FilterConstants.applyMatteFilter);
        //   break;
        // case FilterConstants.vscoA6FilterName:
        //   await photoNotifier.applyFilters(FilterConstants.applyVscoA6Filter);
        //   break;
        case FilterConstants.blackWhiteFilterName:
          await photoNotifier.applyFilters(FilterConstants.applyMonoFilter);
          break;
        // case FilterConstants.cinematicFilterName:
        //   await photoNotifier.applyFilters(
        //     FilterConstants.applyCinematicFilter,
        //   );
        //   break;
        case FilterConstants.photoboothFilterName:
          await photoNotifier.applyFilters(
            FilterConstants.applyPhotoboothFilter,
          );
        default:
          break;
      }

      // Navigate to organize screen after successful filter application
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(15),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF740000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating preview...',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF740000),
              ),
            ),
          ],
        ),
      );
    }

    if (_previewImages.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Color(0xFF740000).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a filter to see preview',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                color: Color(0xFF740000).withOpacity(0.6),
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
          child: ClipRect(
            child: CarouselSlider.builder(
              itemCount: _previewImages.length,
              itemBuilder: (context, index, realIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                viewportFraction:
                    1, // Reduced from 0.85 to show less of adjacent images
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Photo indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library, size: 16, color: Color(0xFF740000)),
              const SizedBox(width: 8),
              Text(
                'Photo ${_currentCarouselIndex + 1} of ${_previewImages.length}',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF740000),
                ),
              ),
            ],
          ),
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
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/design/background.png'),
          fit: BoxFit.fill,
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
                      SizedBox(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () => context.go('/classic/capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF740000),
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

              return Column(
                children: [
                  // Header with back button, title, and skip button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          onPressed: () => context.go('/classic/capture'),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF740000),
                            size: 28,
                          ),
                        ),
                      ),

                      Spacer(),

                      // Title image
                      Image.asset(
                        'assets/design/flipbook-filters/filters_title.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),

                      Spacer(),

                      // Skip button
                      Container(
                        width: 200,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => context.go('/classic/organize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF740000),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'SKIP FILTERS',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Main content area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left panel - Filter selection with doll and preview box
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Doll image (includes "Choose Filters" text)
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/design/flipbook-filters/filters_doll.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'CHOOSE FILTERS',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 39,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              // Filter selection panel - no gap between doll and filters
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Filter list with radio buttons
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: ListView.separated(
                                            padding: EdgeInsets.zero,
                                            itemCount: FilterConstants
                                                .filterDefinitions
                                                .length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(height: 16),
                                            itemBuilder: (context, index) {
                                              final filterDef = FilterConstants
                                                  .filterDefinitions[index];
                                              final isSelected =
                                                  _selectedFilter ==
                                                  filterDef.name;

                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Color(
                                                          0xFF740000,
                                                        ).withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                          20,
                                                        ),
                                                    leading: Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors
                                                                  .transparent,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? Color(
                                                                  0xFF740000,
                                                                )
                                                              : Colors.white,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: isSelected
                                                          ? Icon(
                                                              Icons.check,
                                                              size: 16,
                                                              color: Color(
                                                                0xFF740000,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    title: Text(
                                                      filterDef.name,
                                                      style: TextStyle(
                                                        fontFamily: 'SpaceMono',
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isSelected
                                                            ? Color(0xFF740000)
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      filterDef.description,
                                                      style: TextStyle(
                                                        fontFamily: 'SpaceMono',
                                                        fontSize: 16,
                                                        color: isSelected
                                                            ? Color(
                                                                0xFF740000,
                                                              ).withOpacity(0.8)
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedFilter =
                                                            filterDef.name;
                                                      });
                                                      _generateFilterPreview(
                                                        filterDef.name,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Apply button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 96,
                                        child: ElevatedButton(
                                          onPressed: _isApplyingFilter
                                              ? null
                                              : _applySelectedFilter,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isApplyingFilter
                                                ? Colors.grey
                                                : Colors.white,
                                            foregroundColor: Color(0xFF740000),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _isApplyingFilter
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                              0xFF740000,
                                                            ),
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Applying...',
                                                      style: TextStyle(
                                                        fontFamily: 'SpaceMono',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    // Magic wand icon
                                                    Icon(
                                                      Icons.auto_fix_high,
                                                      size: 32,
                                                      color: Color(0xFF740000),
                                                    ),

                                                    const SizedBox(width: 16),

                                                    Text(
                                                      _selectedFilter ==
                                                              FilterConstants
                                                                  .noFilterName
                                                          ? 'APPLY NO FILTER'
                                                          : 'APPLY FILTER',
                                                      style: TextStyle(
                                                        fontFamily: 'SpaceMono',
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.normal,
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

                        const SizedBox(width: 40),

                        // Right panel - Photo preview
                        Expanded(
                          flex: 3,
                          child: AspectRatio(
                            aspectRatio:
                                1.0, // Changed from 0.72 to make it shorter
                            child: Stack(
                              children: [
                                // Preview background image
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/design/flipbook-filters/classic-preview.png',
                                    fit: BoxFit
                                        .contain, // Changed from cover to contain
                                  ),
                                ),
                                // Preview content
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 220,
                                    right: 220,
                                    top: 180,
                                    bottom: 40,
                                  ),
                                  child: _buildPreviewCarousel(),
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
            loading: () =>
                Center(child: CircularProgressIndicator(color: Colors.white)),
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
                  SizedBox(
                    width: 300,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => context.go('/classic/organize'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF740000),
                      ),
                      child: Text(
                        'Skip to Organize',
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
}
