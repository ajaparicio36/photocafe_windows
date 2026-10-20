import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/takes_grid_widget.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookTakesScreen extends ConsumerWidget {
  const FlipbookTakesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoProvider);
    return EventPage(
      title: 'Video takes',
      subtitle: 'Choose your best video for the flipbook!',
      onBack: () => context.go('/flipbook/capture'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: videoState.when(
              data: (state) => state.videoTakes.isEmpty
                  ? EventMessage(
                      message: 'Record your takes to choose a video.',
                      action: EventButton(
                        label: 'RECORD VIDEO',
                        onPressed: () => context.go('/flipbook/start'),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          child: EventPanel(
                            padding: const EdgeInsets.all(24),
                            child: TakesGridWidget(
                              videoTakes: state.videoTakes,
                              selectedIndex: state.selectedTakeIndex,
                              onTakeSelected: (index) => ref
                                  .read(videoProvider.notifier)
                                  .selectTake(index),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 270,
                          child: EventButton(
                            label: 'PROCEED',
                            icon: Icons.arrow_forward_rounded,
                            height: 64,
                            glossy: true,
                            onPressed: state.selectedTakeIndex == null
                                ? null
                                : () => context.go('/flipbook/filter'),
                          ),
                        ),
                      ],
                    ),
              loading: () => const EventMessage(
                message: 'Loading your takes…',
                loading: true,
              ),
              error: (error, stack) => EventMessage(
                message: 'Your takes could not load: $error',
                action: EventButton(
                  label: 'RETURN TO CAPTURE',
                  onPressed: () => context.go('/flipbook/capture'),
                ),
              ),
            ),
          ),
          Positioned(
            top: -145,
            right: -44,
            child: IgnorePointer(
              child: Image.asset(
                'assets/event/flipbook_videotakes_figure1_topright.png',
                width: 132,
                height: 240,
                fit: BoxFit.contain,
                alignment: Alignment.topRight,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -44,
            child: IgnorePointer(
              child: Image.asset(
                'assets/event/flipbook_videotakes_figure2_bottomleft.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
