import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

class FrameOne extends ConsumerWidget {
  const FrameOne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoStateAsync = ref.watch(photoProvider);

    return photoStateAsync.when(
      data: (photoState) {
        final leftPhotos = photoState.photos.take(4).toList();
        final rightPhotos = leftPhotos;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/frames/frame1.png', fit: BoxFit.fill),
            ),
            ...List.generate(4, (i) {
              return Positioned(
                left: 36,
                top: 36 + i * 285,
                width: 340,
                height: 220,
                child: leftPhotos.length > i
                    ? Image.file(
                        File(leftPhotos[i].imagePath),
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              );
            }),
            ...List.generate(4, (i) {
              return Positioned(
                left: 420,
                top: 36 + i * 285,
                width: 340,
                height: 220,
                child: rightPhotos.length > i
                    ? Image.file(
                        File(rightPhotos[i].imagePath),
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading photos')),
    );
  }
}
