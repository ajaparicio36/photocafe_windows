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
  static const fourFrameFaye = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 7,
        top: 14,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 107,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 200,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 295,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 14,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 107,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 200,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 295,
        width: 140,
        height: 85,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_faye.png',
  );

  // Frame Definitions

  // 4 by 4

  static const fourFrameSixteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 7,
        top: 30,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 136,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 241,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 7,
        top: 347,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 160,
        top: 30,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 136,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 241,
        width: 138,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 160,
        top: 347,
        width: 138,
        height: 100,
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
    id: '4by4_frame_faye',
    name: 'Frame for Faye',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFaye},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameThree,
    fourByFourFrameOne,
  ];
}
