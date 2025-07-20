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
      FramePhotoPosition(left: 13, top: 107.5, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 200, width: 125, height: 78),
      FramePhotoPosition(left: 13, top: 293, width: 125, height: 78),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 158, top: 14, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 107.5, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 200, width: 125, height: 78),
      FramePhotoPosition(left: 158, top: 293, width: 125, height: 78),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame1.png',
  );

  static const fourFrameTwo = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 7.5, top: 41.5, width: 133, height: 85),
      FramePhotoPosition(left: 7.5, top: 134, width: 133, height: 85),
      FramePhotoPosition(left: 7.5, top: 226.5, width: 133, height: 85),
      FramePhotoPosition(left: 7.5, top: 317, width: 133, height: 85),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 158, top: 41.5, width: 133, height: 85),
      FramePhotoPosition(left: 158, top: 134, width: 133, height: 85),
      FramePhotoPosition(left: 158, top: 226.5, width: 133, height: 85),
      FramePhotoPosition(left: 158, top: 317, width: 133, height: 85),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame2.png',
  );

  static const fourFrameThree = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame3.png',
  );

  static const fourFrameFour = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame4.png',
  );

  static const fourFrameFive = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame5.png',
  );

  static const fourFrameSix = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame6.png',
  );

  static const fourFrameSeven = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame7.png',
  );

  static const fourFrameEight = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame8.png',
  );

  static const fourFrameNine = FrameLayout(
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
    frameAssetPath: 'assets/frames/frame9.png',
  );

  // 2x2 Frame Layouts (for 2x2 mode)
  static const twoByTwoLayout = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(left: 9, top: 10, width: 135, height: 165),
      FramePhotoPosition(left: 9, top: 183, width: 135, height: 165),
    ],
    rightColumnPositions: [
      FramePhotoPosition(left: 153, top: 10, width: 135, height: 165),
      FramePhotoPosition(left: 153, top: 183, width: 135, height: 165),
    ],
    topOffset: 0,
    frameAssetPath: 'assets/frames/2by2_frame1.png',
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
    layouts: {FrameLayoutType.fourPhotos: fourFrameEight},
    previewWidgetName: 'FourByFourFramePreview',
  );
  // 2 by 2

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
    fourByFourFrame,
    fourByFourFrameTwo,
    fourByFourFrameThree,
    fourByFourFrameFour,
    fourByFourFrameFive,
    fourByFourFrameSix,
    fourByFourFrameSeven,
    fourByFourFrameEight,
    fourByFourFrameNine,
    twoByTwoFrame, // 2x2 specific frame
    classicFrame, // Legacy frame that works for both
  ];
}
