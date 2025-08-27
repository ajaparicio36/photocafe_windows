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
  VideoPlayerController? _videoPlayerController;
  String? _currentVideoPath;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    final videoState = ref.read(videoProvider).value;
    if (videoState?.videoPath != null &&
        _currentVideoPath != videoState!.videoPath) {
      _currentVideoPath = videoState.videoPath;
      await _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.file(
        File(_currentVideoPath!),
      );
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _applyFilter() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final videoNotifier = ref.read(videoProvider.notifier);
      await videoNotifier.processVideoWithFilter(_selectedFilter);
      context.go('/flipbook/frame');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying filter: $e')));
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
    ref.listen(videoProvider, (_, next) {
      if (next.hasValue && next.value?.videoPath != _currentVideoPath) {
        _initializeVideoPlayer();
      }
    });

    final videoState = ref.watch(videoProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF76220B)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: videoState.when(
            data: (data) {
              if (data?.videoPath == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_outlined,
                        size: 100,
                        color: const Color(0xFFFFFBEE).withOpacity(0.4),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'No video available',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 36,
                          color: const Color(0xFFFFFBEE),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () => context.go('/flipbook/capture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEE),
                            foregroundColor: const Color(0xFF76220B),
                          ),
                          child: Text(
                            'Record Video',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
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
                          onPressed: () => context.go('/flipbook/capture'),
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
                              fontFamily: 'LeagueSpartan',
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFFBEE),
                            ),
                          ),
                          Text(
                            'Choose a filter for your flipbook video',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
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
                          onPressed: () => context.go('/flipbook/frame'),
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
                              fontFamily: 'LeagueSpartan',
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
                          child: _buildFilterSelectionPanel(context),
                        ),

                        const SizedBox(width: 32),

                        // Right panel - Video preview
                        Expanded(
                          flex: 3,
                          child: _buildVideoPreviewPanel(context),
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
                      onPressed: () => context.go('/flipbook/frame'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBEE),
                        foregroundColor: const Color(0xFF76220B),
                      ),
                      child: const Text(
                        'Skip to Frame Selection',
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

  Widget _buildFilterSelectionPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF76220B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Filter',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 32,
              color: const Color(0xFFFFFBEE),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Filter options
          Expanded(
            child: ListView.separated(
              itemCount: VideoFilterConstants.availableFilters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final filterName = VideoFilterConstants.availableFilters[index];
                final isSelected = _selectedFilter == filterName;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFFBEE)
                        : const Color(0xFF5A1908),
                    borderRadius: BorderRadius.circular(16),
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
                          color: isSelected
                              ? const Color(0xFFFFFBEE)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF76220B)
                                : const Color(0xFFFFFBEE),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: const Color(0xFF76220B),
                              )
                            : null,
                      ),
                      title: Text(
                        filterName,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF76220B)
                              : const Color(0xFFFFFBEE),
                        ),
                      ),
                      subtitle: Text(
                        _getFilterDescription(filterName),
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFF76220B).withOpacity(0.8)
                              : const Color(0xFFFFFBEE).withOpacity(0.8),
                        ),
                      ),
                      onTap: () => setState(() => _selectedFilter = filterName),
                    ),
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
              onPressed: _isProcessing ? null : _applyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessing
                    ? const Color(0xFFFFFBEE).withOpacity(0.5)
                    : const Color(0xFFFFFBEE),
                foregroundColor: _isProcessing
                    ? const Color(0xFF76220B).withOpacity(0.5)
                    : const Color(0xFF76220B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.transparent,
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: const Color(0xFF76220B).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Processing Video...',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high_rounded, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          'Apply $_selectedFilter',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
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
    );
  }

  Widget _buildVideoPreviewPanel(BuildContext context) {
    return Container(
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
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFFBEE),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child:
                        (_videoPlayerController?.value.isInitialized ?? false)
                        ? VideoPlayer(_videoPlayerController!)
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFFBEE),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Video info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 24,
                      color: const Color(0xFF76220B),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Flipbook Video Preview',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
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
      ),
    );
  }

  String _getFilterDescription(String filterName) {
    switch (filterName) {
      case 'No Filter':
        return 'Keep your video as it is';
      case 'Vintage':
        return 'Add a classic vintage look with warm tones';
      case 'Black & White':
        return 'Convert to elegant black and white';
      case 'Sepia':
        return 'Apply warm sepia tones';
      default:
        return 'Apply this filter to your video';
    }
  }
}
