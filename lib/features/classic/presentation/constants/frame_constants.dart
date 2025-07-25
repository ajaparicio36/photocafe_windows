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
        top: 13,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 107.5,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 204,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 300,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 156,
        top: 13,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 156,
        top: 107.5,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 156,
        top: 204,
        width: 125,
        height: 83,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 156,
        top: 300,
        width: 125,
        height: 83,
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
        left: 7.5,
        top: 42,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7.5,
        top: 136,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7.5,
        top: 231,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7.5,
        top: 325,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 152,
        top: 42,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 136,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 231,
        width: 134,
        height: 88,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 325,
        width: 134,
        height: 88,
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
        left: 4.5,
        top: 5.5,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4.5,
        top: 104,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4.5,
        top: 202,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4.5,
        top: 300,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 5.5,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 104,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 202,
        width: 146,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 300,
        width: 146,
        height: 92,
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
        left: 6,
        top: 5,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 100,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 198,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 298,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 5,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 100,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 198,
        width: 140,
        height: 93,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 298,
        width: 140,
        height: 93,
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
        left: 6,
        top: 1,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 110,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 219,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 328,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 1,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 110,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 219,
        width: 126,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 328,
        width: 126,
        height: 105,
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
        top: 14,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 109,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 195,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 287,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 152,
        top: 14,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 109,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 195,
        width: 140,
        height: 92,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 287,
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
        left: 15,
        top: 42,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 22,
        top: 136,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 228,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 22,
        top: 322,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 42,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 166,
        top: 136,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 228,
        width: 115,
        height: 65,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 166,
        top: 322,
        width: 115,
        height: 65,
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
        top: 15,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 109.5,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 205,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 298.5,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 15,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 109.5,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 205,
        width: 125,
        height: 78,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 298.5,
        width: 125,
        height: 78,
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
        left: 9,
        top: 40,
        width: 125,
        height: 85,
        rotationDegrees: -4,
      ),
      FramePhotoPosition(
        left: 15,
        top: 139,
        width: 125,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 13,
        top: 229,
        width: 125,
        height: 85,
        rotationDegrees: 4,
      ),
      FramePhotoPosition(
        left: 13,
        top: 324,
        width: 125,
        height: 85,
        rotationDegrees: 0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 40,
        width: 125,
        height: 85,
        rotationDegrees: -4,
      ),
      FramePhotoPosition(
        left: 160,
        top: 139,
        width: 125,
        height: 85,
        rotationDegrees: 0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 229,
        width: 125,
        height: 85,
        rotationDegrees: 4,
      ),
      FramePhotoPosition(
        left: 164,
        top: 324,
        width: 125,
        height: 85,
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
        left: 9,
        top: 10,
        width: 135,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 9,
        top: 186,
        width: 135,
        height: 169,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 149,
        top: 10,
        width: 135,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 149,
        top: 186,
        width: 135,
        height: 169,
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
        left: 17,
        top: 20,
        width: 118,
        height: 125,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 17,
        top: 195,
        width: 118,
        height: 125,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 157,
        top: 20,
        width: 118,
        height: 125,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 195,
        width: 118,
        height: 125,
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
        left: 16,
        top: 14,
        width: 117,
        height: 155,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 16,
        top: 194,
        width: 117,
        height: 155,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 156,
        top: 14,
        width: 117,
        height: 155,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 154,
        top: 194,
        width: 117,
        height: 155,
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
        top: 71,
        width: 137,
        height: 170,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 249,
        width: 137,
        height: 170,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 147,
        top: 71,
        width: 137,
        height: 170,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 147,
        top: 249,
        width: 137,
        height: 170,
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
        left: 9,
        top: 29,
        width: 140,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 9,
        top: 219,
        width: 140,
        height: 169,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 147,
        top: 29,
        width: 140,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 147,
        top: 219,
        width: 140,
        height: 169,
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
        top: 19,
        width: 139,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 204,
        width: 139,
        height: 169,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 154,
        top: 19,
        width: 139,
        height: 169,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 154,
        top: 203,
        width: 139,
        height: 169,
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
