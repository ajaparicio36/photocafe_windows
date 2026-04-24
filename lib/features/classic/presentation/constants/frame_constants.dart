enum FrameLayoutType { twoPhotos, fourPhotos, fourLandscapePhotos, threePhotos }

class FramePhotoPosition {
  final double left;
  final double top;
  final double width;
  final double height;
  final double rotationDegrees;

  const FramePhotoPosition({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.rotationDegrees = 0.0,
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
  // 4x2 Frame Layout (4 photos, portrait strips)
  static const fourByTwoFrameOneLayout = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 13, top: 12, width: 132, height: 95),
      FramePhotoPosition(left: 13, top: 111.5, width: 132, height: 95),
      FramePhotoPosition(left: 13, top: 212, width: 132, height: 95),
      FramePhotoPosition(left: 13, top: 312, width: 132, height: 95),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 160, top: 12, width: 132, height: 95),
      FramePhotoPosition(left: 160, top: 111.5, width: 132, height: 95),
      FramePhotoPosition(left: 160, top: 212, width: 132, height: 95),
      FramePhotoPosition(left: 160, top: 316, width: 132, height: 95),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_1.png',
  );

  // 3x2 Frame Layouts (3 photos, portrait strips)
  static const threeByTwoFrameOneLayout = FrameLayout(
    type: FrameLayoutType.threePhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 13, top: 12, width: 132, height: 126),
      FramePhotoPosition(left: 13, top: 148, width: 132, height: 126),
      FramePhotoPosition(left: 13, top: 284, width: 132, height: 126),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 160, top: 12, width: 132, height: 126),
      FramePhotoPosition(left: 160, top: 148, width: 132, height: 126),
      FramePhotoPosition(left: 160, top: 284, width: 132, height: 126),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/3by2_frame1.png',
  );

  static const threeByTwoFrameTwoLayout = FrameLayout(
    type: FrameLayoutType.threePhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 13, top: 12, width: 132, height: 126),
      FramePhotoPosition(left: 13, top: 148, width: 132, height: 126),
      FramePhotoPosition(left: 13, top: 284, width: 132, height: 126),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 160, top: 12, width: 132, height: 126),
      FramePhotoPosition(left: 160, top: 148, width: 132, height: 126),
      FramePhotoPosition(left: 160, top: 284, width: 132, height: 126),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/3by2_frame2.png',
  );

  // Frame Definitions

  static const FrameDefinition fourByTwoFrameOne = FrameDefinition(
    id: '4by2_frame_one',
    name: 'Click Click Frame 3',
    description: '4 photo portrait strip',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByTwoFrameOneLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition threeByTwoFrameOne = FrameDefinition(
    id: '3by2_frame_one',
    name: 'ADCON Day 1',
    description: '3 photo portrait strip',
    supportedLayouts: [FrameLayoutType.threePhotos],
    layouts: {FrameLayoutType.threePhotos: threeByTwoFrameOneLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition threeByTwoFrameTwo = FrameDefinition(
    id: '3by2_frame_two',
    name: 'ADCON Day 2',
    description: '3 photo portrait strip',
    supportedLayouts: [FrameLayoutType.threePhotos],
    layouts: {FrameLayoutType.threePhotos: threeByTwoFrameTwoLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByTwoFrameOne,
    threeByTwoFrameOne,
    threeByTwoFrameTwo,
  ];
}
