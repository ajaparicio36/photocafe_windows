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
        left: 5,
        top: 32,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 137.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 350,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 160,
        top: 32,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 137.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 350,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_1.png',
  );

  static const fourByFourLayoutTwo = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 42.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 142.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 348,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158.5,
        top: 42.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 142.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 348,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_2.png',
  );

  static const fourByFourLayoutThree = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 12,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 133,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 243,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 360,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158.5,
        top: 12,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 133,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 243,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 360,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_3.png',
  );

  static const fourByFourLayoutFour = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 4,
        top: 4,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4,
        top: 110,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4,
        top: 236,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4,
        top: 346,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 157.5,
        top: 4,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157.5,
        top: 110,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157.5,
        top: 236,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157.5,
        top: 346,
        width: 143,
        height: 110,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 0,
    frameAssetPath: 'assets/frames/frame_4.png',
  );

  static const fourByFourLayoutFive = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 42.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 142.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 348,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158.5,
        top: 42.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 142.5,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 245,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158.5,
        top: 348,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_5.png',
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
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Frame Three',
    description: 'A classic kodak frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFour = FrameDefinition(
    id: '4by4_frame_four',
    name: 'Frame Four',
    description: 'A classic black frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFive = FrameDefinition(
    id: '4by4_frame_five',
    name: 'Sunny Side Market Frame',
    description: 'A frame created by the Sunny Side Market',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutFive},
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
        top: -8,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 106,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 222,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 337.5,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 167,
        top: -8,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 167,
        top: 106,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 167,
        top: 222,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 167,
        top: 337.5,
        width: 114,
        height: 128,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 0,
    frameAssetPath: 'assets/frames/landscape_1.png',
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
    fourByFourFrameTwo,
    fourByFourFrameThree,
    fourByFourFrameFour,
    fourByFourFrameFive,
    // Add landscape frames
    landscapeFrameOneDefinition,
  ];
}
