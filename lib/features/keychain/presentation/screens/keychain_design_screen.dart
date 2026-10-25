import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (_reviewOutput != null && _reviewSelectionKey != _selectionKey(session))
      _reviewOutput = null;
    final currentIndex = session.designIndex;
    final selection = session.variants[currentIndex];
    final frames = KeychainFrameCatalog.allClassicFrames;
    final filters = KeychainFilterCatalog.allFilters;
    final photos = ref.watch(photoProvider).value?.photos ?? [];
    return EventPage(
      title: session.isReview ? 'Final review' : 'Keychain',
      subtitle: session.isReview
          ? 'Your four designs, together on one sheet'
          : 'Choose a frame and filter for each little memory',
      onBack: _isRendering ? null : () => context.go('/keychain/capture'),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < keychainVariantCount; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextButton(
                      onPressed: _isRendering || session.isReview
                          ? null
                          : () => ref
                                .read(keychainSessionProvider.notifier)
                                .setDesignIndex(index),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            !session.isReview && currentIndex == index
                            ? Colors.white
                            : EventDesign.red,
                        foregroundColor:
                            !session.isReview && currentIndex == index
                            ? EventDesign.red
                            : Colors.white,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Text(
                        'Design ${index + 1}',
                        style: const TextStyle(fontFamily: EventDesign.body),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: session.isReview
                      ? EventSection(
                          title: 'Ready to print',
                          child: EventPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Four designs. One keepsake.',
                                  style: TextStyle(
                                    fontFamily: EventDesign.body,
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Each mini strip keeps its own frame and filter. Your still photos will be printed; the Bouncy Preview is included in your soft copies.',
                                  style: TextStyle(
                                    fontFamily: EventDesign.body,
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                for (
                                  var i = 0;
                                  i < session.variants.length;
                                  i++
                                )
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Text(
                                      'Design ${i + 1}: ${frames.firstWhere((f) => f.id == session.variants[i].frameId).name}',
                                      style: const TextStyle(
                                        fontFamily: EventDesign.body,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                const Text(
                                  'Go back to Design 4 to make a change before printing.',
                                  style: TextStyle(
                                    fontFamily: EventDesign.body,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: EventSection(
                                title: 'Select frame',
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    2,
                                    2,
                                    10,
                                    2,
                                  ),
                                  itemCount: frames.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) => EventChoice(
                                    title: frames[index].name,
                                    selected:
                                        selection.frameId == frames[index].id,
                                    onTap: _isRendering
                                        ? null
                                        : () => ref
                                              .read(
                                                keychainSessionProvider
                                                    .notifier,
                                              )
                                              .setVariantFrame(
                                                currentIndex,
                                                frames[index].id,
                                              ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: EventSection(
                                title: 'Select filter',
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    2,
                                    2,
                                    10,
                                    2,
                                  ),
                                  itemCount: filters.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) => EventChoice(
                                    title: filters[index].name,
                                    selected:
                                        selection.filterId == filters[index].id,
                                    onTap: _isRendering
                                        ? null
                                        : () => ref
                                              .read(
                                                keychainSessionProvider
                                                    .notifier,
                                              )
                                              .setVariantFilter(
                                                currentIndex,
                                                filters[index].id,
                                              ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 38),
                Expanded(
                  flex: 5,
                  child: EventSection(
                    title: session.isReview ? 'Complete sheet' : 'Preview',
                    figure: 'assets/event/frames_figure1.png',
                    figureWidth: 175,
                    child: EventPanel(
                      child: photos.length != 4
                          ? const Center(
                              child: Text(
                                'Capture four photos to design your keychain.',
                              ),
                            )
                          : BouncyPreview(
                              foregroundColor: Colors.white,
                              photos: photos,
                              selections: session.isReview
                                  ? session.variants
                                  : [selection],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isRendering)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: EventDesign.red,
              ),
            ),
          _buildNavigation(session),
        ],
      ),
    );
  }

  Widget _buildNavigation(KeychainSessionState session) {
    final notifier = ref.read(keychainSessionProvider.notifier);
    if (session.isReview)
      return Row(
        children: [
          SizedBox(
            width: 280,
            child: EventButton(
              label: 'BACK TO DESIGN 4',
              icon: Icons.arrow_back,
              onPressed: _isRendering ? null : _backToDesignFour,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 325,
            child: EventButton(
              label: _isRendering ? 'PREPARING…' : 'CONTINUE TO PRINT',
              icon: Icons.print_outlined,
              onPressed: _isRendering ? null : _continueToPrint,
            ),
          ),
        ],
      );
    final currentIndex = session.designIndex;
    final isDesignFour = currentIndex == keychainVariantCount - 1;
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: EventButton(
            label: 'PREVIOUS',
            icon: Icons.arrow_back,
            onPressed: _isRendering || currentIndex == 0
                ? null
                : () => notifier.setDesignIndex(currentIndex - 1),
          ),
        ),
        const Spacer(),
        Text(
          'DESIGN ${currentIndex + 1} OF $keychainVariantCount',
          style: const TextStyle(
            fontFamily: EventDesign.body,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 280,
          child: EventButton(
            label: _isRendering
                ? 'PREPARING…'
                : isDesignFour
                ? 'VIEW FINAL REVIEW'
                : 'NEXT DESIGN',
            icon: isDesignFour ? Icons.preview_outlined : Icons.arrow_forward,
            onPressed: _isRendering
                ? null
                : isDesignFour
                ? _showReview
                : () => notifier.setDesignIndex(currentIndex + 1),
          ),
        ),
      ],
    );
  }
}
