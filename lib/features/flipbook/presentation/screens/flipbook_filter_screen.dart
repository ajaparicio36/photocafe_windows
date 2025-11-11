import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/videos/domain/data/constants/filter_constants.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:video_player/video_player.dart';

class FlipbookFilterScreen extends ConsumerStatefulWidget {
  const FlipbookFilterScreen({super.key});

  @override
  ConsumerState<FlipbookFilterScreen> createState() =>
      _FlipbookFilterScreenState();
}

class _FlipbookFilterScreenState extends ConsumerState<FlipbookFilterScreen> {
  String _selectedFilter = VideoFilterConstants.noFilterName;
  bool _isProcessing = false;
  bool _isGeneratingPreview = false;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    // Initialize with original video
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideoPlayer();
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    final videoState = ref.read(videoProvider).value;
    if (videoState?.videoPath != null) {
      await _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.file(
        File(videoState!.videoPath!),
      );
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _applyFilterPreview(String filterName) async {
    if (_isGeneratingPreview || _isProcessing) return;

    setState(() {
      _isGeneratingPreview = true;
      _selectedFilter = filterName;
    });

    try {
      final videoNotifier = ref.read(videoProvider.notifier);

      // If "No Filter" is selected, use the original video
      if (filterName == VideoFilterConstants.noFilterName) {
        final videoState = ref.read(videoProvider).value;
        if (videoState?.videoPath != null) {
          await _updateVideoPreview(videoState!.videoPath!);
        }
      } else {
        // Apply filter and get preview video path
        final filteredVideoPath = await videoNotifier
            .applyVideoFilterForPreview(filterName);

        if (filteredVideoPath != null && mounted) {
          await _updateVideoPreview(filteredVideoPath);
        }
      }
    } catch (e) {
      print('Error applying filter preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error previewing filter: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPreview = false;
        });
      }
    }
  }

  Future<void> _updateVideoPreview(String videoPath) async {
    final currentPosition =
        _videoPlayerController?.value.position ?? Duration.zero;

    await _videoPlayerController?.dispose();

    _videoPlayerController = VideoPlayerController.file(File(videoPath));
    await _videoPlayerController!.initialize();
    await _videoPlayerController!.setLooping(true);

    // Restore position if video is long enough
    if (currentPosition < _videoPlayerController!.value.duration) {
      await _videoPlayerController!.seekTo(currentPosition);
    }

    await _videoPlayerController!.play();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _applySelectedFilter() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final videoNotifier = ref.read(videoProvider.notifier);

      // If "No Filter" is selected, just split frames without applying filter
      if (_selectedFilter == VideoFilterConstants.noFilterName) {
        await videoNotifier.splitVideoIntoFrames();
      } else {
        // Apply filter and split frames
        await videoNotifier.processVideoWithFilter(_selectedFilter);
      }

      if (mounted) {
        context.go('/flipbook/frame');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying filter: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
            data: (data) {
              if (data.videoPath == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_outlined,

                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No video available',
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
                          onPressed: () => context.go('/flipbook/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF740000),
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
                          onPressed: () => context.go('/flipbook/takes'),
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
                          onPressed: _isProcessing || _isGeneratingPreview
                              ? null
                              : () async {
                                  setState(() {
                                    _isProcessing = true;
                                  });

                                  try {
                                    final videoNotifier = ref.read(
                                      videoProvider.notifier,
                                    );
                                    await videoNotifier.splitVideoIntoFrames();

                                    if (mounted) {
                                      context.go('/flipbook/frame');
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error processing video: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                    }
                                  }
                                },
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
                        // Left panel - Filter selection with doll
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Doll image with text
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

                              // Filter selection panel
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
                                            itemCount: VideoFilterConstants
                                                .availableFilters
                                                .length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(height: 24),
                                            itemBuilder: (context, index) {
                                              final filterName =
                                                  VideoFilterConstants
                                                      .availableFilters[index];
                                              final isSelected =
                                                  _selectedFilter == filterName;

                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(36),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: () =>
                                                      _applyFilterPreview(
                                                        filterName,
                                                      ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 48,
                                                          horizontal: 16,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        // Radio button
                                                        Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? Color(
                                                                      0xFF740000,
                                                                    )
                                                                  : Colors
                                                                        .white,
                                                              width: 2,
                                                            ),
                                                            color: Colors
                                                                .transparent,
                                                          ),
                                                          child: isSelected
                                                              ? Center(
                                                                  child: Container(
                                                                    width: 12,
                                                                    height: 12,
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Color(
                                                                        0xFF740000,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                          width: 32,
                                                        ),
                                                        // Filter name
                                                        Expanded(
                                                          child: Text(
                                                            filterName,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'SpaceMono',
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: isSelected
                                                                  ? Color(
                                                                      0xFF740000,
                                                                    )
                                                                  : Colors
                                                                        .white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
                                          onPressed:
                                              _isProcessing ||
                                                  _isGeneratingPreview
                                              ? null
                                              : _applySelectedFilter,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                (_isProcessing ||
                                                    _isGeneratingPreview)
                                                ? Colors.grey
                                                : Colors.white,
                                            foregroundColor: Color(0xFF740000),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _isProcessing
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
                                                    Icon(
                                                      Icons.auto_fix_high,
                                                      size: 32,
                                                      color: Color(0xFF740000),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Text(
                                                      _selectedFilter ==
                                                              VideoFilterConstants
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

                        // Right panel - Video preview
                        Expanded(
                          flex: 3,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              children: [
                                // Preview background image
                                Positioned.fill(
                                  bottom: 320,
                                  child: Image.asset(
                                    'assets/design/flipbook-filters/filters_preview.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                // Video preview content
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 170,
                                    right: 170,
                                    top: 180,
                                    bottom: 340,
                                  ),
                                  child: _buildVideoPreview(),
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
                      onPressed: () => context.go('/flipbook/frame'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF740000),
                      ),
                      child: Text(
                        'Skip to Frame Selection',
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

  Widget _buildVideoPreview() {
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

    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 60,
              color: Color(0xFF740000).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: VideoPlayer(_videoPlayerController!),
    );
  }
}
