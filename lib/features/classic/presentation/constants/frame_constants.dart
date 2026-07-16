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
  static const fourFrameIdc = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 6,
        top: 3,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 108,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 212,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 317,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159.5,
        top: 3,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159.5,
        top: 108,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159.5,
        top: 212,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159.5,
        top: 317,
        width: 124,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_idc.png',
  );

  // Frame Definitions

  // 4 by 4

  static const fourFrameSixteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 0,
        top: 3.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 113,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 224,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 332,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 151,
        top: 3.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 151,
        top: 113,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 151,
        top: 224,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 151,
        top: 332,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_cc.png',
  );

  static const FrameDefinition fourByFourFrameOne = FrameDefinition(
    id: '4by4_frame_cc',
    name: 'Click Click Frame',
    description: 'A classic Click Click frame!',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSixteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_idc',
    name: 'Akwave Frame',
    description: 'Summertide Signals',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameIdc},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameThree,
    fourByFourFrameOne,
  ];
}
