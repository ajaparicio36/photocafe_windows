import 'package:photocafe_windows/widgets/event_design.dart';
import 'dart:io';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

/// Arguments for the isolate filter function. Must be a simple sendable object.
class _FilterIsolateArgs {
  final Uint8List imageBytes;
  final String filterName;

  const _FilterIsolateArgs(this.imageBytes, this.filterName);
}

/// Top-level function that runs inside an isolate via compute().
/// Must be top-level (not a closure or instance method) so it doesn't
/// capture any unsendable Flutter widget state.
Uint8List? _applyFilterInIsolateTopLevel(_FilterIsolateArgs args) {
  final originalImage = img.decodeImage(args.imageBytes);
  if (originalImage == null) return null;

  // Downscale for preview – 600px on the longest side is plenty for
  // the carousel and keeps processing fast.
  const int previewMaxDimension = 600;
  img.Image previewImage;
  if (originalImage.width > previewMaxDimension ||
      originalImage.height > previewMaxDimension) {
    if (originalImage.width >= originalImage.height) {
      previewImage = img.copyResize(
        originalImage,
        width: previewMaxDimension,
        interpolation: img.Interpolation.average,
      );
    } else {
      previewImage = img.copyResize(
        originalImage,
        height: previewMaxDimension,
        interpolation: img.Interpolation.average,
      );
    }
  } else {
    previewImage = originalImage;
  }

  img.Image filteredImage;
  switch (args.filterName) {
    case FilterConstants.noFilterName:
      filteredImage = previewImage;
      break;
    case FilterConstants.vintageFilterName:
      filteredImage = FilterConstants.applyVintageFilter(previewImage);
      break;
    case FilterConstants.hdrFilterName:
      filteredImage = FilterConstants.applyHdrFilter(previewImage);
      break;
    // case FilterConstants.matteFilterName:
    //   filteredImage = FilterConstants.applyMatteFilter(previewImage);
    //   break;
    // case FilterConstants.vscoA6FilterName:
    //   filteredImage = FilterConstants.applyVscoA6Filter(previewImage);
    //   break;
    case FilterConstants.blackWhiteFilterName:
      filteredImage = FilterConstants.applyMonoFilter(previewImage);
      break;
    // case FilterConstants.cinematicFilterName:
    //   filteredImage = FilterConstants.applyCinematicFilter(previewImage);
    //   break;
    case FilterConstants.photoboothFilterName:
      filteredImage = FilterConstants.applyPhotoboothFilter(previewImage);
      break;
    default:
      filteredImage = previewImage;
  }

  return Uint8List.fromList(img.encodeJpg(filteredImage, quality: 80));
}

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
    final currentFilter = ref.read(bouncySessionProvider).classicFilterId;
    _selectedFilter = FilterConstants.filterDefinitions
        .firstWhere((filter) => filter.id == currentFilter)
        .name;
    _generateFilterPreview(_selectedFilter!);
  }

  /// Generates downscaled preview thumbnails in background isolates.
  /// Each photo is processed in its own isolate so the main UI thread stays
  /// responsive.
  Future<void> _generateFilterPreview(String filterName) =>
      ref.read(bouncySessionProvider).track(_filterPreviewWork(filterName));
  Future<void> _filterPreviewWork(String filterName) async {
    final session = ref.read(bouncySessionProvider);
    final generation = session.generation;
    if (!mounted) return;

    setState(() {
      _isGeneratingPreview = true;
      _previewImages = [];
    });

    // Allow the loading UI to render before starting heavy work
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final photoState = ref.read(photoProvider).value;
      if (photoState == null || photoState.photos.isEmpty) return;

      // Read all file bytes first (I/O is async, doesn't block UI)
      final photoPaths = <String>[];
      final photoBytesList = <Uint8List>[];
      for (final photo in photoState.photos) {
        final file = File(photo.originalPath ?? photo.imagePath);
        if (await file.exists()) {
          photoPaths.add(photo.imagePath);
          photoBytesList.add(await file.readAsBytes());
        }
      }

      // Process all photos in parallel isolates using compute()
      // which properly serialises arguments without capturing widget state.
      final futures = photoBytesList.map((imageBytes) {
        return compute(
          _applyFilterInIsolateTopLevel,
          _FilterIsolateArgs(imageBytes, filterName),
        );
      }).toList();

      final previewImages = await Future.wait(futures);

      // Only update state if the selected filter hasn't changed while
      // we were processing (user may have tapped another filter).
      if (!mounted ||
          generation != session.generation ||
          _selectedFilter != filterName)
        return;

      setState(() {
        _previewImages = previewImages
            .where((b) => b != null)
            .cast<Uint8List>()
            .toList();
      });
    } catch (e) {
      debugPrint('Error generating filter preview: $e');
    } finally {
      if (mounted && _selectedFilter == filterName) {
        setState(() {
          _isGeneratingPreview = false;
        });
      }
    }
  }

  Future<void> _applySelectedFilter() async {
    if (_selectedFilter == null) return;

    ref.read(bouncySessionProvider).classicFilterId = FilterConstants
        .filterDefinitions
        .firstWhere((f) => f.name == _selectedFilter)
        .id;
    // If "No Filter" is selected, just navigate
    if (_selectedFilter == FilterConstants.noFilterName) {
      ref.read(photoProvider.notifier).restoreOriginalPhotos();
      context.go('/classic/organize');
      return;
    }

    setState(() {
      _isApplyingFilter = true;
    });

    // Let the loading UI render before starting heavy work
    await Future.delayed(const Duration(milliseconds: 50));

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
      if (mounted) {
        context.go('/classic/organize');
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter could not be applied: $e. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingFilter = false;
        });
      }
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating preview...',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a filter to see preview',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
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
                      fit: BoxFit.contain,
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
    final busy = _isApplyingFilter;
    final hasPhotos =
        ref.watch(photoProvider).value?.photos.isNotEmpty ?? false;
    return EventPage(
      title: 'Filters',
      subtitle: 'Choose your own filter to enhance your photos',
      onBack: busy ? null : () => context.go('/classic/capture'),
      trailing: SizedBox(
        width: 170,
        child: EventButton(
          label: 'SKIP FILTERS',
          height: 48,
          onPressed: busy || !hasPhotos
              ? null
              : () {
                  setState(
                    () => _selectedFilter = FilterConstants.noFilterName,
                  );
                  _applySelectedFilter();
                },
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: EventSection(
              title: 'Choose filters',
              figure: 'assets/event/filters_figure1.png',
              figureWidth: 62,
              figureAtStart: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
                      itemCount: FilterConstants.filterDefinitions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final filter = FilterConstants.filterDefinitions[index];
                        return EventChoice(
                          title: filter.name,
                          description: filter.description,
                          selected: _selectedFilter == filter.name,
                          onTap: busy
                              ? null
                              : () {
                                  setState(() => _selectedFilter = filter.name);
                                  _generateFilterPreview(filter.name);
                                },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  EventButton(
                    label: busy
                        ? 'APPLYING FILTER…'
                        : 'APPLY ${(_selectedFilter ?? 'FILTER').toUpperCase()}',
                    icon: Icons.auto_fix_high,
                    onPressed: busy || !hasPhotos ? null : _applySelectedFilter,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 5,
            child: EventSection(
              title: 'Preview',
              figure: 'assets/event/filters_figure2.png',
              child: EventPanel(child: _buildPreviewCarousel()),
            ),
          ),
        ],
      ),
    );
  }
}
