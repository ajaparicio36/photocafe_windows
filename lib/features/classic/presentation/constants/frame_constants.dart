enum FrameLayoutType { twoPhotos, fourPhotos, threePhotos, fourLandscapePhotos }

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
  // Classic Frame Layouts (for 4x4 mode)
  static const fourByFourLayoutOne = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 13,
        top: 12,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 111.5,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 212,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 312,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 160,
        top: 12,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 111.5,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 212,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 316,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame1.png',
  );

  // Frame Definitions

  // 4 by 4

  static const FrameDefinition fourByFourFrameOne = FrameDefinition(
    id: '4by4_frame_one',
    name: 'Frame One',
    description: 'A classic frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwo = FrameDefinition(
    id: '4by4_frame_two',
    name: 'Frame Two',
    description: 'A daily times frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Frame Three',
    description: 'A classic kodak frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFour = FrameDefinition(
    id: '4by4_frame_four',
    name: 'Frame Four',
    description: 'A classic black frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFive = FrameDefinition(
    id: '4by4_frame_five',
    name: 'Sunny Side Market Frame',
    description: 'A frame created by the Sunny Side Market',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  // 2 by 2

  // static const FrameDefinition twoByTwoFrameOne = FrameDefinition(
  //   id: '2by2_frame_one',
  //   name: 'Frame One',
  //   description: 'A classic red 2-by-2 frame.',
  //   supportedLayouts: [FrameLayoutType.twoPhotos],
  //   layouts: {FrameLayoutType.twoPhotos: twoFrameOne},
  //   previewWidgetName: 'TwoByTwoFramePreview',
  // );

  // static const twoFrameOne = FrameLayout(
  //   type: FrameLayoutType.twoPhotos,
  //   leftColumnPositions: [
  //     FramePhotoPosition(
  //       left: 8,
  //       top: 9,
  //       width: 145,
  //       height: 182,
  //       rotationDegrees: 0.0,
  //     ),
  //     FramePhotoPosition(
  //       left: 8,
  //       top: 196,
  //       width: 145,
  //       height: 182,
  //       rotationDegrees: 0.0,
  //     ),
  //   ],
  //   rightColumnPositions: [
  //     FramePhotoPosition(
  //       left: 154,
  //       top: 9,
  //       width: 145,
  //       height: 182,
  //       rotationDegrees: 0.0,
  //     ),
  //     FramePhotoPosition(
  //       left: 154,
  //       top: 196,
  //       width: 145,
  //       height: 182,
  //       rotationDegrees: 0.0,
  //     ),
  //   ],
  //   topOffset: 100,
  //   frameAssetPath: 'assets/frames/2by2_frame1.png',
  // );

  // Landscape Frame Layouts (for landscape mode - rotated 4x4)
  static const landscapeFrameOne = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 20,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 104.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 216,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 330.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 175,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 104.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 216,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 330.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_one.png',
  );

  // Frame Definitions
  static const FrameDefinition landscapeFrameOneDefinition = FrameDefinition(
    id: 'landscape_frame_one',
    name: 'Landscape Frame One',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameOne},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameOne,
    // Add landscape frames
    landscapeFrameOneDefinition,
  ];
}
