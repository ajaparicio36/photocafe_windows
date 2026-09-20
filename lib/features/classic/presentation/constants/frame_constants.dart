enum FrameLayoutType { twoPhotos, fourPhotos, fourLandscapePhotos }

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
  final String previewWidgetName;

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

  static const fourFrameThirteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 0,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 117,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 230,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 344,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 0,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 117,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 230,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 344,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame13.png',
  );

  static const popupFrameOne = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 0,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 115,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 230,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 344,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 0,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 115,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 230,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 344,
        width: 142,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/cpu_frame_1.png',
  );

  static const popupFrameTwo = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 8,
        top: 8,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 110,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 208,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8,
        top: 308,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 161,
        top: 8,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 161,
        top: 110,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 161,
        top: 208,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 161,
        top: 308,
        width: 136,
        height: 94,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/cpu_frame_2.png',
  );

  static const popupFrameThree = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 3,
        top: 3,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3,
        top: 103,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3,
        top: 200,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 3,
        top: 295,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 3,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 103,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 200,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 295,
        width: 145,
        height: 96,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/cpu_frame_3.png',
  );

  static const popupFrameFour = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 23,
        top: 28,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 23,
        top: 120,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 23,
        top: 210,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 23,
        top: 302,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 176,
        top: 28,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 176,
        top: 120,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 176,
        top: 210,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 176,
        top: 302,
        width: 107,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/cpu_frame_5.png',
  );

  static const popupFrameFive = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 19,
        top: 65,
        width: 118,
        height: 86,
        rotationDegrees: 5,
      ),
      FramePhotoPosition(
        left: -5,
        top: 157,
        width: 135,
        height: 93,
        rotationDegrees: -3.85,
      ),
      FramePhotoPosition(
        left: 30,
        top: 248,
        width: 116,
        height: 84,
        rotationDegrees: 5,
      ),
      FramePhotoPosition(
        left: 3,
        top: 352,
        width: 138,
        height: 95,
        rotationDegrees: -0.5,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 174,
        top: 69,
        width: 118,
        height: 86,
        rotationDegrees: 5.0,
      ),
      FramePhotoPosition(
        left: 150,
        top: 162,
        width: 135,
        height: 93,
        rotationDegrees: -3.85,
      ),
      FramePhotoPosition(
        left: 182,
        top: 253,
        width: 116,
        height: 84,
        rotationDegrees: 5.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 354,
        width: 138,
        height: 95,
        rotationDegrees: -0.5,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/cpu_frame_4.png',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Classic Frame One',
    description: 'A classic black and white frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwelve = FrameDefinition(
    id: '4by4_frame_twelve',
    name: 'Classic Frame Two',
    description: 'A frame for classic monochrome',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwelve},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThirteen = FrameDefinition(
    id: '4by4_frame_thirteen',
    name: 'Classic Frame Three',
    description: 'A frame with plain retro feel',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThirteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupOne = FrameDefinition(
    id: 'popup_frame_one',
    name: 'UWCF Frame One',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupTwo = FrameDefinition(
    id: 'popup_frame_two',
    name: 'UWCF Frame Two',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupThree = FrameDefinition(
    id: 'popup_frame_three',
    name: 'UWCF Frame Three',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupFour = FrameDefinition(
    id: 'popup_frame_four',
    name: 'UWCF Frame Four',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupFive = FrameDefinition(
    id: 'popup_frame_five',
    name: 'UWCF Frame Five',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameFive},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    popupOne,
    popupTwo,
    popupThree,
    popupFour,
    popupFive,
    fourByFourFrameThree,
    fourByFourFrameTwelve,
    fourByFourFrameThirteen,
  ];
}
