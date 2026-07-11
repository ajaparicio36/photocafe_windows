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
  static const fourFramePh = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 9,
        top: 7.5,
        width: 135,
        height: 102,
        rotationDegrees: 1.8,
      ),
      FramePhotoPosition(
        left: 8,
        top: 120,
        width: 135,
        height: 102,
        rotationDegrees: 2,
      ),
      FramePhotoPosition(
        left: 13,
        top: 215,
        width: 135,
        height: 102,
        rotationDegrees: -1.8,
      ),
      FramePhotoPosition(
        left: 10,
        top: 315,
        width: 135,
        height: 102,
        rotationDegrees: -1.8,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 160,
        top: 7.5,
        width: 135,
        height: 102,
        rotationDegrees: 1.8,
      ),
      FramePhotoPosition(
        left: 159,
        top: 120,
        width: 135,
        height: 102,
        rotationDegrees: 2,
      ),
      FramePhotoPosition(
        left: 164,
        top: 215,
        width: 135,
        height: 102,
        rotationDegrees: -1.8,
      ),
      FramePhotoPosition(
        left: 161,
        top: 315,
        width: 135,
        height: 102,
        rotationDegrees: -1.8,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_ph.png',
  );

  static const threeFrameRx = FrameLayout(
    type: FrameLayoutType.threePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 15,
        top: 26,
        width: 122,
        height: 118,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 156,
        width: 122,
        height: 123,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 15,
        top: 289,
        width: 122,
        height: 127,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 168,
        top: 26,
        width: 122,
        height: 118,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 168,
        top: 156,
        width: 122,
        height: 123,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 168,
        top: 289,
        width: 122,
        height: 127,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_rx.png',
  );

  static const fourFrameUsa = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 11,
        top: 13,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 111,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 208,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 306,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 163,
        top: 13,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 163,
        top: 111,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 163,
        top: 208,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 163,
        top: 306,
        width: 131,
        height: 86,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame_usa.png',
  );

  // Frame Definitions

  // 4 by 4

  static const FrameDefinition fourByFourFrameOne = FrameDefinition(
    id: '4by4_frame_one',
    name: 'PharMed Frame',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFramePh},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwo = FrameDefinition(
    id: '3by3_frame_two',
    name: 'Department of Pharmacy Frame',
    description: '',
    supportedLayouts: [FrameLayoutType.threePhotos],
    layouts: {FrameLayoutType.threePhotos: threeFrameRx},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'San Agustinian Frame',
    description: '',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameUsa},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameOne,
    fourByFourFrameTwo,
    fourByFourFrameThree,
  ];
}
