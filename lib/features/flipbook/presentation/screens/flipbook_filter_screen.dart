import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
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

    return ScreenContainer(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Apply a Filter',
            subtitle: 'Choose a filter to apply to your video',
            backRoute: '/flipbook/capture',
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter selection panel
                Expanded(flex: 2, child: _buildFilterSelectionPanel(context)),
                const SizedBox(width: 32),
                // Video preview
                Expanded(flex: 3, child: _buildVideoPreviewPanel(context)),
              ],
            ),
          ),
          if (videoState.isLoading || _isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing video...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSelectionPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: VideoFilterConstants.availableFilters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final filterName = VideoFilterConstants.availableFilters[index];
                final isSelected = _selectedFilter == filterName;
                return ListTile(
                  title: Text(
                    filterName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: Radio<String>(
                    value: filterName,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                  tileColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onTap: () => setState(() => _selectedFilter = filterName),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _applyFilter,
              icon: _isProcessing
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check_circle_outline, size: 32),
              label: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Apply Filter & Proceed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: (_videoPlayerController?.value.isInitialized ?? false)
                      ? VideoPlayer(_videoPlayerController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
