enum FrameLayoutType { twoPhotos, fourPhotos }

class FramePhotoPosition {
  final double left;
  final double top;
  final double width;
  final double height;

  const FramePhotoPosition({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class FrameLayout {
  final FrameLayoutType type;
  final List<FramePhotoPosition> leftColumnPositions;
  final List<FramePhotoPosition> rightColumnPositions;
  final double topOffset;
  final String frameAssetPath;

  const FrameLayout({
    required this.type,
    required this.leftColumnPositions,
    required this.rightColumnPositions,
    required this.topOffset,
    required this.frameAssetPath,
  });
}

class FrameDefinition {
  final String id;
  final String name;
  final String description;
  final List<FrameLayoutType> supportedLayouts;
  final Map<FrameLayoutType, FrameLayout> layouts;
  final String previewWidgetName; // For dynamic widget creation

  const FrameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.supportedLayouts,
    required this.layouts,
    required this.previewWidgetName,
  });
}

class FrameConstants {
  // Classic Frame Layouts (for 4x4 mode)
  static const classicFourPhotoLayout = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 13, top: 14, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 106.5, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 199, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 291.5, width: 125, height: 78),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 158, top: 14, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 106.5, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 199, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 291.5, width: 125, height: 78),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame1.png',
  );

  // 2x2 Frame Layouts (for 2x2 mode)
  static const twoByTwoLayout = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 20, top: 50, width: 140, height: 250),
      FramePhotoPosition(left: 20, top: 230, width: 140, height: 250),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 180, top: 50, width: 140, height: 250),
      FramePhotoPosition(left: 180, top: 230, width: 140, height: 250),
    ],
    topOffset: 50,
    frameAssetPath: 'assets/frames/2by2_frame1.png',
  );

  // Frame Definitions
  static const FrameDefinition fourByFourFrame = FrameDefinition(
    id: '4by4_frame_one',
    name: '4x4 Classic Frame',
    description: 'A classic 4-photo strip layout.',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: classicFourPhotoLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition twoByTwoFrame = FrameDefinition(
    id: '2by2_frame_one',
    name: '2x2 Portrait Frame',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoByTwoLayout},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  // Legacy classic frame - keeping for backwards compatibility
  static const classicTwoPhotoLayout = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 13, top: 100, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 192.5, width: 125, height: 78),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 158, top: 100, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 192.5, width: 125, height: 78),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/frame1.png',
  );

  static const FrameDefinition classicFrame = FrameDefinition(
    id: 'frame_one',
    name: 'Classic Frame',
    description: 'A decorative strip layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos, FrameLayoutType.fourPhotos],
    layouts: {
      FrameLayoutType.twoPhotos: classicTwoPhotoLayout,
      FrameLayoutType.fourPhotos: classicFourPhotoLayout,
    },
    previewWidgetName: 'ClassicFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrame, // 4x4 specific frame
    twoByTwoFrame, // 2x2 specific frame
    classicFrame, // Legacy frame that works for both
  ];
}
