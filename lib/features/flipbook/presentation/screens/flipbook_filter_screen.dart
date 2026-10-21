import 'package:photocafe_windows/widgets/event_design.dart';
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
  String? _previewError;

  @override
  void initState() {
    super.initState();
    // Initialize with original video
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideoPlayer().catchError((Object error) {
        if (mounted)
          setState(
            () => _previewError = 'Video preview could not load. Please retry.',
          );
      });
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
    final busy = _isProcessing || _isGeneratingPreview;
    return EventPage(
      title: 'Filters',
      subtitle: 'Choose your own filter to enhance your video',
      onBack: busy ? null : () => context.go('/flipbook/takes'),
      trailing: SizedBox(
        width: 170,
        child: EventButton(
          label: 'SKIP FILTERS',
          height: 48,
          onPressed: busy || videoState.value?.videoPath == null
              ? null
              : () {
                  setState(
                    () => _selectedFilter = VideoFilterConstants.noFilterName,
                  );
                  _applySelectedFilter();
                },
        ),
      ),
      child: videoState.when(
        loading: () =>
            const EventMessage(message: 'Loading your video…', loading: true),
        error: (error, stack) => EventMessage(
          message: 'Video could not load: $error',
          action: EventButton(
            label: 'RETURN TO TAKES',
            onPressed: () => context.go('/flipbook/takes'),
          ),
        ),
        data: (data) => data.videoPath == null
            ? EventMessage(
                message: 'Record a video before choosing a filter.',
                action: EventButton(
                  label: 'RECORD VIDEO',
                  onPressed: () => context.go('/flipbook/start'),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              itemCount:
                                  VideoFilterConstants.availableFilters.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final filter = VideoFilterConstants
                                    .availableFilters[index];
                                return EventChoice(
                                  title: filter,
                                  description: _description(filter),
                                  selected: filter == _selectedFilter,
                                  onTap: busy
                                      ? null
                                      : () => _applyFilterPreview(filter),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          EventButton(
                            label: _isProcessing
                                ? 'PROCESSING…'
                                : 'APPLY ${_selectedFilter.toUpperCase()}',
                            icon: Icons.auto_fix_high,
                            onPressed: busy ? null : _applySelectedFilter,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    flex: 6,
                    child: EventSection(
                      title: 'Preview',
                      figure: 'assets/event/filters_figure2.png',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 365,
                            child: EventPanel(
                              child: _previewError != null
                                  ? EventMessage(
                                      message: _previewError!,
                                      action: EventButton(
                                        label: 'RETRY PREVIEW',
                                        onPressed: () {
                                          setState(() => _previewError = null);
                                          _initializeVideoPlayer().catchError((
                                            Object error,
                                          ) {
                                            if (mounted)
                                              setState(
                                                () => _previewError =
                                                    'Video preview could not load. Please retry.',
                                              );
                                          });
                                        },
                                      ),
                                    )
                                  : _videoPlayerController
                                            ?.value
                                            .isInitialized ==
                                        true
                                  ? Center(
                                      child: AspectRatio(
                                        aspectRatio: _videoPlayerController!
                                            .value
                                            .aspectRatio,
                                        child: VideoPlayer(
                                          _videoPlayerController!,
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          if (busy) ...[
                            const SizedBox(height: 20),
                            Text(
                              _isGeneratingPreview
                                  ? 'Generating filter preview…'
                                  : 'Preparing your flipbook…',
                              style: const TextStyle(
                                fontFamily: EventDesign.body,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          if (_videoPlayerController?.value.isInitialized ==
                              true)
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _videoPlayerController!.value.isPlaying
                                    ? _videoPlayerController!.pause()
                                    : _videoPlayerController!.play();
                              }),
                              icon: Icon(
                                _videoPlayerController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              label: Text(
                                _videoPlayerController!.value.isPlaying
                                    ? 'Pause preview'
                                    : 'Play preview',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _description(String filter) => switch (filter) {
    VideoFilterConstants.noFilterName => 'Keep your video as it is',
    VideoFilterConstants.vintageFilterName => 'Warm tones with a vintage feel',
    VideoFilterConstants.blackAndWhiteFilterName =>
      'A timeless monochrome finish',
    VideoFilterConstants.sepiaFilterName => 'Classic sepia tones',
    VideoFilterConstants.brightnessFilterName => 'Brighten your video',
    VideoFilterConstants.contrastFilterName => 'Bring out contrast and detail',
    _ => '',
  };
}
