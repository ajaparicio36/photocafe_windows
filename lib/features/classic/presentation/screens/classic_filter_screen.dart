import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        const SnackBar(content: Text('Filter applied successfully!')),
      );

      // Navigate to organize screen
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

  @override
  Widget build(BuildContext context) {
    final photoStateAsync = ref.watch(photoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Filters'),
        actions: [
          TextButton(
            onPressed: () => context.go('/classic/organize'),
            child: const Text('Skip Filters'),
          ),
        ],
      ),
      body: photoStateAsync.when(
        data: (photoState) {
          if (photoState.photos.isEmpty) {
            return const Center(child: Text('No photos available'));
          }

          return Column(
            children: [
              // Photo preview grid
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: photoState.photos.length,
                    itemBuilder: (context, index) {
                      final photo = photoState.photos[index];
                      return Card(
                        child: Image.file(
                          File(photo.imagePath),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Filter selection
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose a Filter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter options
                      Expanded(
                        child: ListView.builder(
                          itemCount: FilterConstants.availableFilters.length,
                          itemBuilder: (context, index) {
                            final filterName =
                                FilterConstants.availableFilters[index];
                            return RadioListTile<String>(
                              title: Text(filterName),
                              value: filterName,
                              groupValue: _selectedFilter,
                              onChanged: (value) {
                                setState(() {
                                  _selectedFilter = value;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isApplyingFilter
                              ? null
                              : _applySelectedFilter,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isApplyingFilter
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
                                    Text('Applying Filter...'),
                                  ],
                                )
                              : Text(
                                  _selectedFilter != null
                                      ? 'Apply $_selectedFilter'
                                      : 'Select a Filter',
                                ),
                        ),
                      ),
                    ],
                  ),
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
                onPressed: () => context.go('/classic/organize'),
                child: const Text('Skip to Organize'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
