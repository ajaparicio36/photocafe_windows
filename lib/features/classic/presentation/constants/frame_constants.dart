enum FrameLayoutType { twoPhotos, fourPhotos }

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
  static const classicFourPhotoLayout = FrameLayout(
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

  static const fourFrameTwo = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 6.5,
        top: 43,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 141,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 242,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 340,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 43,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 141,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 242,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 340,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame2.png',
  );

  static const fourFrameThree = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 3.5,
        top: 5.5,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3.5,
        top: 104,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3.5,
        top: 209,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3.5,
        top: 315,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 5.5,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 104,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 209,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 315,
        width: 154,
        height: 104,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame3.png',
  );

  static const fourFrameFour = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 5,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 105,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 210,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 315,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 152,
        top: 5,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 105,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 210,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 315,
        width: 148,
        height: 105,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame4.png',
  );

  static const fourFrameFive = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 10,
        top: 1,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 115,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 233,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 346,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 164,
        top: 1,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 115,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 233,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 346,
        width: 130,
        height: 110,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame5.png',
  );

  static const fourFrameSix = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 8,
        top: 15,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 112,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 206,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 304,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 157,
        top: 15,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 112,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 206,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 304,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame6.png',
  );

  static const fourFrameSeven = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 12,
        top: 44,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 22,
        top: 144,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 12,
        top: 243,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 22,
        top: 342,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 165,
        top: 44,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 175,
        top: 144,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 243,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 175,
        top: 342,
        width: 120,
        height: 70,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame7.png',
  );

  static const fourFrameEight = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 13,
        top: 20,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 115.5,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 216,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 310.5,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 167,
        top: 20,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 167,
        top: 115.5,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 167,
        top: 216,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 167,
        top: 310.5,
        width: 132,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame8.png',
  );

  static const fourFrameNine = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 7,
        top: 45,
        width: 132,
        height: 95,
        rotationDegrees: -4,
      ),
      FramePhotoPosition(
        left: 15,
        top: 146,
        width: 132,
        height: 95,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 238,
        width: 132,
        height: 95,
        rotationDegrees: 4,
      ),
      FramePhotoPosition(
        left: 13,
        top: 339,
        width: 132,
        height: 95,
        rotationDegrees: 0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 155,
        top: 45,
        width: 132,
        height: 95,
        rotationDegrees: -4,
      ),
      FramePhotoPosition(
        left: 165,
        top: 146,
        width: 132,
        height: 95,
        rotationDegrees: 0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 238,
        width: 132,
        height: 95,
        rotationDegrees: 4,
      ),
      FramePhotoPosition(
        left: 169,
        top: 339,
        width: 132,
        height: 95,
        rotationDegrees: 0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame9.png',
  );
  // Frame Definitions

  // 4 by 4

  static const FrameDefinition fourByFourFrame = FrameDefinition(
    id: '4by4_frame_one',
    name: 'Frame One',
    description: 'A frame with pole borders',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: classicFourPhotoLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwo = FrameDefinition(
    id: '4by4_frame_two',
    name: 'Frame Two',
    description: 'A frame with different layout',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Frame Three',
    description: 'A frame with another layout',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFour = FrameDefinition(
    id: '4by4_frame_four',
    name: 'Frame Four',
    description: 'A frame with yet another layout',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFive = FrameDefinition(
    id: '4by4_frame_five',
    name: 'Frame Five',
    description: 'A frame with a unique layout',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFive},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSix = FrameDefinition(
    id: '4by4_frame_six',
    name: 'Frame Six',
    description: 'A frame with a different design',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSix},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSeven = FrameDefinition(
    id: '4by4_frame_seven',
    name: 'Frame Seven',
    description: 'A frame with a unique style',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSeven},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameEight = FrameDefinition(
    id: '4by4_frame_eight',
    name: 'Frame Eight',
    description: 'A frame with a modern look',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameEight},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameNine = FrameDefinition(
    id: '4by4_frame_nine',
    name: 'Frame Nine',
    description: 'A frame with a classic design',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameNine},
    previewWidgetName: 'FourByFourFramePreview',
  );

  // 2 by 2

  static const FrameDefinition twoByTwoFrameOne = FrameDefinition(
    id: '2by2_frame_one',
    name: 'Frame One',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameOne},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameTwo = FrameDefinition(
    id: '2by2_frame_two',
    name: 'Frame Two',
    description: ' A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameTwo},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameThree = FrameDefinition(
    id: '2by2_frame_three',
    name: 'Frame Three',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameThree},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameFour = FrameDefinition(
    id: '2by2_frame_four',
    name: 'Frame Four',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameFour},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameFive = FrameDefinition(
    id: '2by2_frame_five',
    name: 'Frame Five',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameFive},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameSix = FrameDefinition(
    id: '2by2_frame_six',
    name: 'Frame Six',
    description: 'A portrait-oriented 2-photo layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameSix},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const twoFrameOne = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 8,
        top: 9,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 196,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 154,
        top: 9,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 154,
        top: 196,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame1.png',
  );

  static const twoFrameTwo = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 16,
        top: 20,
        width: 127,
        height: 134,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 16,
        top: 206,
        width: 127,
        height: 134,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 161,
        top: 20,
        width: 127,
        height: 134,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 161,
        top: 206,
        width: 127,
        height: 134,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame2.png',
  );

  static const twoFrameThree = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 18,
        top: 14,
        width: 134,
        height: 172,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 18,
        top: 197,
        width: 134,
        height: 172,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 14,
        width: 134,
        height: 172,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 197,
        width: 134,
        height: 172,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame3.png',
  );

  static const twoFrameFour = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 8,
        top: 74,
        width: 149,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 264,
        width: 149,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 147,
        top: 74,
        width: 149,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 147,
        top: 264,
        width: 149,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame4.png',
  );

  static const twoFrameFive = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 8,
        top: 25,
        width: 146,
        height: 186,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 227,
        width: 146,
        height: 186,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 157,
        top: 25,
        width: 146,
        height: 186,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 227,
        width: 146,
        height: 186,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame5.png',
  );

  static const twoFrameSix = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 15,
        top: 20,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 212,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 154,
        top: 20,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 154,
        top: 212,
        width: 145,
        height: 182,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame6.png',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrame,
    fourByFourFrameTwo,
    fourByFourFrameThree,
    fourByFourFrameFour,
    fourByFourFrameFive,
    fourByFourFrameSix,
    fourByFourFrameSeven,
    fourByFourFrameEight,
    fourByFourFrameNine,
    twoByTwoFrameOne,
    twoByTwoFrameTwo,
    twoByTwoFrameThree,
    twoByTwoFrameFour,
    twoByTwoFrameFive,
    twoByTwoFrameSix,
  ];
}
