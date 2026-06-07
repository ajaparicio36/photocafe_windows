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
  static const fourByFourLayoutFour = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 0,
        width: 144,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 115,
        width: 144,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 230,
        width: 144,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 345,
        width: 144,
        height: 114,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 153,
        top: 0,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 115,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 230,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 153,
        top: 345,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame18.png',
  );

  static const fourFrameTwoTwo = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5,
        top: 12,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 110,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 207,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5,
        top: 306,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 12,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 110,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 207,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 306,
        width: 142,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_ja.png',
  );

  // Frame Definitions

  // 4 by 4

  static const FrameDefinition fourByFourFrameOne = FrameDefinition(
    id: '4by4_frame_one',
    name: 'J&A Frame',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwoTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwo = FrameDefinition(
    id: '4by4_frame_ja',
    name: 'ClickClick Frame',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourByFourLayoutFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameOne,
    fourByFourFrameTwo,
  ];
}
