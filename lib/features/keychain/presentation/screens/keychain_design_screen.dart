import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/keychain/domain/data/providers/keychain_session_notifier.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

class KeychainDesignScreen extends ConsumerStatefulWidget {
  const KeychainDesignScreen({super.key});

  @override
  ConsumerState<KeychainDesignScreen> createState() =>
      _KeychainDesignScreenState();
}

class _KeychainDesignScreenState extends ConsumerState<KeychainDesignScreen> {
  final KeychainCompositionService _compositionService =
      KeychainCompositionService();

  KeychainRenderOutput? _reviewOutput;
  String? _reviewSelectionKey;
  bool _isRendering = false;

  String _selectionKey(KeychainSessionState session) {
    return session.variants
        .map((selection) => '${selection.frameId}:${selection.filterId}')
        .join('|');
  }

  Future<void> _showReview() async {
    if (_isRendering) return;
    if (!ref
        .read(bouncySessionProvider)
        .valid(
          ref.read(photoProvider).value?.photos.map((p) => p.captureId) ?? [],
        )) {
      _showError('Retake incomplete shots before continuing.');
      return;
    }
    final photoState = ref.read(photoProvider).value;
    if (photoState == null ||
        photoState.photos.length != keychainVariantCount) {
      _showError('Capture exactly four photos before reviewing.');
      return;
    }

    final bouncy = ref.read(bouncySessionProvider);
    final generation = bouncy.generation;
    setState(() => _isRendering = true);
    try {
      final session = ref.read(keychainSessionProvider);
      final output = await bouncy.track(
        _compositionService.render(session: session, photos: photoState.photos),
      );
      if (!mounted || generation != bouncy.generation) return;
      setState(() {
        _reviewOutput = output;
        _reviewSelectionKey = _selectionKey(session);
      });
      ref.read(keychainSessionProvider.notifier).enterReview();
    } catch (error) {
      _showError('Could not render the four-up review: $error');
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  Future<void> _continueToPrint() async {
    if (_isRendering) return;
    if (!ref
        .read(bouncySessionProvider)
        .valid(
          ref.read(photoProvider).value?.photos.map((p) => p.captureId) ?? [],
        )) {
      _showError('Retake incomplete shots before continuing.');
      return;
    }
    final output = _reviewOutput;
    final photoState = ref.read(photoProvider).value;
    if (output == null || photoState == null) {
      _showError('Render the final review before printing.');
      return;
    }

    final bouncy = ref.read(bouncySessionProvider);
    final generation = bouncy.generation;
    setState(() => _isRendering = true);
    try {
      final mediaBundle = await bouncy.track(
        output.persist(photoState.tempPath),
      );
      if (mounted && generation == bouncy.generation) {
        context.go(
          '/keychain/print',
          extra: KeychainPrintArguments(
            output: output,
            mediaBundle: mediaBundle,
          ),
        );
      }
    } catch (error) {
      _showError('Could not prepare Keychain print media: $error');
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  void _backToDesignFour() {
    _reviewOutput = null;
    _reviewSelectionKey = null;

    ref.read(keychainSessionProvider.notifier).returnToDesignFour();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _compositionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(keychainSessionProvider);

    if (_reviewOutput != null &&
        _reviewSelectionKey != _selectionKey(session)) {
      _reviewOutput = null;
    }

    final currentIndex = session.designIndex;
    final selection = session.variants[currentIndex];
    final frames = KeychainFrameCatalog.allClassicFrames;
    final filters = KeychainFilterCatalog.allFilters;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/design/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/keychain/capture'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF740000),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      session.isReview
                          ? 'FINAL FOUR-UP REVIEW'
                          : 'DESIGN ${currentIndex + 1} OF $keychainVariantCount',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: session.isReview
                            ? _buildReviewPreview()
                            : _buildVariantPreview(currentIndex),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 2,
                        child: session.isReview
                            ? _buildReviewDetails()
                            : _buildControls(
                                frames: frames,
                                filters: filters,
                                selection: selection,
                                currentIndex: currentIndex,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _buildNavigation(session),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isRendering
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildVariantPreview(int index) => _previewCard(
    title: 'Bouncy Preview',
    child: BouncyPreview(
      photos: ref.watch(photoProvider).requireValue.photos,
      selections: [ref.watch(keychainSessionProvider).variants[index]],
    ),
    footer: 'Print uses your original still photos',
  );

  Widget _buildReviewPreview() => _previewCard(
    title: 'Complete four-design sheet',
    child: BouncyPreview(
      photos: ref.watch(photoProvider).requireValue.photos,
      selections: ref.watch(keychainSessionProvider).variants,
    ),
    footer: 'Motion preview • still print is separate',
  );

  Widget _previewCard({
    required String title,
    required Widget child,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Color(0xFF740000),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
          const SizedBox(height: 12),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: const Color(0xFF740000).withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF740000).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READY TO PRINT',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Each quadrant is an independently rendered design. You can go back to Design 4 to change its frame or filter before printing.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          Spacer(),
          Text(
            'The selected frames and filters are used for the still print.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls({
    required List<FrameDefinition> frames,
    required List<FilterDefinition> filters,
    required KeychainVariantSelection selection,
    required int currentIndex,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF740000).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FRAME',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('frame-$currentIndex-${selection.frameId}'),
            initialValue: selection.frameId,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final frame in frames)
                DropdownMenuItem<String>(
                  value: frame.id,
                  child: Text(frame.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isRendering
                ? null
                : (value) {
                    if (value != null) {
                      ref
                          .read(keychainSessionProvider.notifier)
                          .setVariantFrame(currentIndex, value);
                    }
                  },
          ),
          const SizedBox(height: 24),
          const Text(
            'FILTER',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('filter-$currentIndex-${selection.filterId}'),
            initialValue: selection.filterId,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final filter in filters)
                DropdownMenuItem<String>(
                  value: filter.id,
                  child: Text(filter.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isRendering
                ? null
                : (value) {
                    if (value != null) {
                      ref
                          .read(keychainSessionProvider.notifier)
                          .setVariantFilter(currentIndex, value);
                    }
                  },
          ),
          const Spacer(),
          Text(
            'You can reuse a frame or filter. Each design keeps its own choices.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(KeychainSessionState session) {
    final notifier = ref.read(keychainSessionProvider.notifier);
    if (session.isReview) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: _isRendering ? null : _backToDesignFour,
            icon: const Icon(Icons.arrow_back),
            label: const Text('BACK TO DESIGN 4'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isRendering ? null : _continueToPrint,
            icon: const Icon(Icons.print_rounded),
            label: const Text('CONTINUE TO PRINT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF740000),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            ),
          ),
        ],
      );
    }

    final currentIndex = session.designIndex;
    final isFirst = currentIndex == 0;
    final isDesignFour = currentIndex == keychainVariantCount - 1;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: isFirst
              ? null
              : () => notifier.setDesignIndex(currentIndex - 1),
          icon: const Icon(Icons.arrow_back),
          label: const Text('PREVIOUS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _isRendering
              ? null
              : isDesignFour
              ? _showReview
              : () => notifier.setDesignIndex(currentIndex + 1),
          icon: Icon(
            isDesignFour ? Icons.preview_rounded : Icons.arrow_forward,
          ),
          label: Text(isDesignFour ? 'VIEW FINAL REVIEW' : 'NEXT DESIGN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF740000),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          ),
        ),
      ],
    );
  }
}
