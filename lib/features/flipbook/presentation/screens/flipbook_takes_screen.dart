import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/takes_grid_widget.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/takes_header_widget.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookTakesScreen extends ConsumerWidget {
  const FlipbookTakesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/design/flipbook-start/flipbook_takes.png',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: videoState.when(
          data: (state) {
            final selectedIndex = state.selectedTakeIndex;
            final hasSelection = selectedIndex != null;

            return Stack(
              children: [
                Column(
                  children: [
                    // Takes Grid
                    const SizedBox(height: 180),
                    Expanded(
                      child: TakesGridWidget(
                        videoTakes: state.videoTakes,
                        selectedIndex: selectedIndex,
                        onTakeSelected: (index) {
                          ref.read(videoProvider.notifier).selectTake(index);
                        },
                      ),
                    ),

                    // Bottom spacing for proceed button
                    const SizedBox(height: 40),
                  ],
                ),

                // Proceed Button (only show when a take is selected)
                if (hasSelection)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          context.go('/flipbook/filter');
                        },
                        child: Image.asset(
                          'assets/design/flipbook-start/flipbook_proceed.png',
                          width: 300,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Back Button
                Positioned(
                  top: 60,
                  left: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () => context.go('/flipbook/capture'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
