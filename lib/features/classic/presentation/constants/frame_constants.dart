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
      FramePhotoPosition(left: 13, top: 14, width: 126, height: 126),
      FramePhotoPosition(left: 13, top: 130, width: 126, height: 126),
      FramePhotoPosition(left: 13, top: 255, width: 126, height: 126),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 165, top: 14, width: 126, height: 126),
      FramePhotoPosition(left: 165, top: 130, width: 126, height: 126),
      FramePhotoPosition(left: 165, top: 255, width: 126, height: 126),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/3by2_frame1.png',
  );

  static const fourFrameMissDiana = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 153,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_missdiana.png',
  );

  static const fourFrameTwelve = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 153,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame12.png',
  );

  static const threeByTwoFrameTwoLayout = FrameLayout(
    type: FrameLayoutType.threePhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 15, top: 8, width: 123, height: 123),
      FramePhotoPosition(left: 15, top: 130, width: 123, height: 123),
      FramePhotoPosition(left: 15, top: 255, width: 123, height: 123),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 168, top: 8, width: 123, height: 123),
      FramePhotoPosition(left: 168, top: 130, width: 123, height: 123),
      FramePhotoPosition(left: 168, top: 255, width: 123, height: 123),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/3by2_frame2.png',
  );

  // Landscape 4x2 Frame Layouts (4 photos, landscape strips)
  static const fourLandscapeFrameOneLayout = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 153,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame12.png',
  );

  static const fourLandscapeFrameTwoLayout = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 153,
        top: 0,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 115,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 230,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 345,
        width: 152,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_missdiana.png',
  );

  // Frame Definitions

  // 2x2 Frame Layout (Photo Box - 4 photos in 2x2 grid)
  static const twoByTwoFrameOneLayout = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 0, top: 0, width: 152, height: 180),
      FramePhotoPosition(left: 0, top: 185, width: 152, height: 180),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 153, top: 0, width: 152, height: 180),
      FramePhotoPosition(left: 153, top: 185, width: 152, height: 180),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame12.png',
  );

  static const FrameDefinition twoByTwoFrameOne = FrameDefinition(
    id: '2by2_frame_one',
    name: 'Photo Box',
    description: '4 photos in 2x2 grid layout',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoByTwoFrameOneLayout},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition fourByTwoFrameOne = FrameDefinition(
    id: '4by2_frame_one',
    name: 'Click Click Frame 3',
    description: '4 photo portrait strip',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByTwoFrameOneLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwelve = FrameDefinition(
    id: '4by4_frame_twelve',
    name: 'Frame One',
    description: 'A frame with plain retro feel',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwelve},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameMissDiana = FrameDefinition(
    id: '4by4_frame_missdiana',
    name: 'Frame Two',
    description: 'A special frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameMissDiana},
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

  static const FrameDefinition fourLandscapeFrameOne = FrameDefinition(
    id: 'landscape_frame_one',
    name: 'Landscape Frame One',
    description: '4 photo landscape strip',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: fourLandscapeFrameOneLayout},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static const FrameDefinition fourLandscapeFrameTwo = FrameDefinition(
    id: 'landscape_frame_two',
    name: 'Landscape Frame Two',
    description: '4 photo landscape strip',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: fourLandscapeFrameTwoLayout},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameTwelve,
    fourByFourFrameMissDiana,
    twoByTwoFrameOne,
    fourLandscapeFrameOne,
    fourLandscapeFrameTwo,
  ];
}
