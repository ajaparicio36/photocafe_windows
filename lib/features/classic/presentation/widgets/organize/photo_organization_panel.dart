import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/core/colors/colors.dart';

class PhotoOrganizationPanel extends StatelessWidget {
  final List<PhotoModel> sortedPhotos;
  final Function(int, int) onReorder;

  const PhotoOrganizationPanel({
    super.key,
    required this.sortedPhotos,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DRAG TO REORDER PHOTOS',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Draggable photo list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: sortedPhotos.length,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                final photo = sortedPhotos[index];
                return Container(
                  key: ValueKey(photo.index),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 0,
                    color: Color(0xFF740000).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white, width: 2),
                    ),
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Photo thumbnail
                          Container(
                            width: 180,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(photo.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Photo info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Photo ${index + 1}',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Position: ${photo.index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
