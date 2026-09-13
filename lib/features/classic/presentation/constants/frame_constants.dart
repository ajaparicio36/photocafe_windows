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
    frameAssetPath: 'assets/frames/popup_frame_1.png',
  );

  static const popupFrameTwo = FrameLayout(
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
        top: 138,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 244,
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
        left: 157,
        top: 32,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 138,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 244,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 157,
        top: 350,
        width: 143,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/popup_frame_2.png',
  );

  static const popupFrameThree = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 15,
        top: 15,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 117,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 216,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 317,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 170,
        top: 15,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 170,
        top: 117,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 170,
        top: 216,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 170,
        top: 317,
        width: 119,
        height: 98,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/popup_frame_3.png',
  );

  static const popupFrameFour = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 28,
        top: 49,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 28,
        top: 141,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 28,
        top: 233,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 28,
        top: 323,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 178,
        top: 49,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 178,
        top: 141,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 178,
        top: 233,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 178,
        top: 323,
        width: 99,
        height: 90,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/popup_frame_4.png',
  );

  static const popupFrameFive = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 24,
        top: 57,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 24,
        top: 150,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 24,
        top: 243,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 24,
        top: 338,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 177,
        top: 57,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 177,
        top: 150,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 177,
        top: 243,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 177,
        top: 338,
        width: 104,
        height: 89,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/popup_frame_5.png',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Frame One',
    description: 'A classic black and white frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwelve = FrameDefinition(
    id: '4by4_frame_twelve',
    name: 'Frame Two',
    description: 'A frame for classic monochrome',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwelve},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThirteen = FrameDefinition(
    id: '4by4_frame_thirteen',
    name: 'Frame Three',
    description: 'A frame with plain retro feel',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThirteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupOne = FrameDefinition(
    id: 'popup_frame_one',
    name: 'Frame Four',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameOne},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupTwo = FrameDefinition(
    id: 'popup_frame_two',
    name: 'Frame Five',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupThree = FrameDefinition(
    id: 'popup_frame_three',
    name: 'Frame Six',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupFour = FrameDefinition(
    id: 'popup_frame_four',
    name: 'Frame Seven',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition popupFive = FrameDefinition(
    id: 'popup_frame_five',
    name: 'Frame Eight',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: popupFrameFive},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameThree,
    fourByFourFrameTwelve,
    fourByFourFrameThirteen,
    popupOne,
    popupTwo,
    popupThree,
    popupFour,
    popupFive,
  ];
}
