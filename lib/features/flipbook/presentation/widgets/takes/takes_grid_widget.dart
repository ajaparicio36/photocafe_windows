import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/flipbook/presentation/widgets/takes/take_preview_widget.dart';

class TakesGridWidget extends StatelessWidget {
  final List<String> videoTakes;
  final int? selectedIndex;
  final ValueChanged<int> onTakeSelected;
  const TakesGridWidget({
    super.key,
    required this.videoTakes,
    required this.selectedIndex,
    required this.onTakeSelected,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 22,
        mainAxisSpacing: 22,
        mainAxisExtent: (constraints.maxHeight - 22) / 2,
      ),
      itemCount: videoTakes.length,
      itemBuilder: (context, index) => TakePreviewWidget(
        videoPath: videoTakes[index],
        takeNumber: index + 1,
        isSelected: selectedIndex == index,
        onTap: () => onTakeSelected(index),
      ),
    ),
  );
}
