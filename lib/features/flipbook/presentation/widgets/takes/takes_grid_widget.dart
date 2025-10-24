import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/take_preview_widget.dart';

class TakesGridWidget extends StatelessWidget {
  final List<String> videoTakes;
  final int? selectedIndex;
  final Function(int) onTakeSelected;

  const TakesGridWidget({
    super.key,
    required this.videoTakes,
    required this.selectedIndex,
    required this.onTakeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 240),
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 240,
            mainAxisSpacing: 10,
            childAspectRatio: 16 / 10,
          ),
          itemCount: videoTakes.length,
          itemBuilder: (context, index) {
            return TakePreviewWidget(
              videoPath: videoTakes[index],
              takeNumber: index + 1,
              isSelected: selectedIndex == index,
              onTap: () => onTakeSelected(index),
            );
          },
        ),
      ),
    );
  }
}
