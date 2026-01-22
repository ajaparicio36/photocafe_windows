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

  static const fourFrameTen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 10,
        top: 0,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 113,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 229,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 10,
        top: 344,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 164,
        top: 0,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 113,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 229,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 164,
        top: 344,
        width: 130,
        height: 114,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame11.png',
  );

  static const fourFrameEleven = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 3.5,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8.5,
        top: 124,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 1.5,
        top: 230,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8.5,
        top: 334,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 124,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 148,
        top: 230,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 334,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame11.png',
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

  static const fourFrameFourteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 6,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 134,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 240,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 344,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 155,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 134,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 240,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 344,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame15.png',
  );

  static const fourFrameFifteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 6,
        top: 5,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 114,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 227,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6,
        top: 344,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 5,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 114,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 227,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 344,
        width: 140,
        height: 100,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame16.png',
  );

  static const fourFrameSixteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 3.5,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8.5,
        top: 124,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 1.5,
        top: 230,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 8.5,
        top: 334,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 150,
        top: 9.5,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 124,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 148,
        top: 230,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 155,
        top: 334,
        width: 154,
        height: 120,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame17.png',
  );

  static const fourFrameSeventeen = FrameLayout(
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

  static const fourFrameEighteen = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 11,
        top: 15,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 124,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 238,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11,
        top: 352,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 165,
        top: 15,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 128,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 240,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 352,
        width: 125,
        height: 80,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frame19.png',
  );

  static const fourFrameDinagyang = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 6.5,
        top: 16,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 130,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 230,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 6.5,
        top: 328,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 16,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 130,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 230,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 328,
        width: 140,
        height: 115,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frameDngyg.png',
  );

  static const fourFrameDagyangPopup = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 5.5,
        top: 50,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5.5,
        top: 149,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5.5,
        top: 249,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 5.5,
        top: 348,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: 50,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 149,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 249,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 158,
        top: 348,
        width: 142,
        height: 98,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frameDagyangPopup.png',
  );

  static const fourFrameChrome = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 1,
        top: 0,
        width: 150,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 110,
        width: 150,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: -3,
        top: 220,
        width: 150,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 0,
        top: 332,
        width: 150,
        height: 118,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 149,
        top: 0,
        width: 150,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 152,
        top: 110,
        width: 153,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 149,
        top: 220,
        width: 150,
        height: 115,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 149,
        top: 332,
        width: 150,
        height: 118,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frameChrome.png',
  );

  static const fourFrameSouthside = FrameLayout(
    type: FrameLayoutType.fourPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 11.5,
        top: 15,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11.5,
        top: 125,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11.5,
        top: 233,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 11.5,
        top: 341,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 165,
        top: 15,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 125,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 233,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 165,
        top: 341,
        width: 123,
        height: 105,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/frameSouthside.png',
  );

  // Frame Definitions

  // 4 by 4

  static const FrameDefinition fourByFourFrame = FrameDefinition(
    id: '4by4_frame_one',
    name: 'Frame One',
    description: 'A frame with beautiful pole borders',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: classicFourPhotoLayout},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTwo = FrameDefinition(
    id: '4by4_frame_two',
    name: 'Frame Two',
    description: 'A cute black and white frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTwo},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameThree = FrameDefinition(
    id: '4by4_frame_three',
    name: 'Frame Three',
    description: 'A classic black and white frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameThree},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFour = FrameDefinition(
    id: '4by4_frame_four',
    name: 'Frame Four',
    description: 'A black dominant frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFour},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFive = FrameDefinition(
    id: '4by4_frame_five',
    name: 'Frame Five',
    description: 'A film strip style frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFive},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSix = FrameDefinition(
    id: '4by4_frame_six',
    name: 'Frame One',
    description: 'A spotify themed frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSix},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSeven = FrameDefinition(
    id: '4by4_frame_seven',
    name: 'Frame Seven',
    description: 'A pixel art theme frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSeven},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameEight = FrameDefinition(
    id: '4by4_frame_eight',
    name: 'Frame Eight',
    description: 'A frame with a cute photoframe design',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameEight},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameNine = FrameDefinition(
    id: '4by4_frame_nine',
    name: 'Frame Nine',
    description: 'A camera screen frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameNine},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameTen = FrameDefinition(
    id: '4by4_frame_ten',
    name: 'CPUR Frame',
    description: 'A frame in collaboration with CPUR',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameTen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameEleven = FrameDefinition(
    id: '4by4_frame_eleven',
    name: 'CPU Prelim Frame',
    description: 'A frame to give you good luck for your prelims!',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameEleven},
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

  static const FrameDefinition fourByFourFrameFourteen = FrameDefinition(
    id: '4by4_frame_fourteen',
    name: 'Frame Four',
    description: 'A frame with JPB design',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFourteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameFifteen = FrameDefinition(
    id: '4by4_frame_fifteen',
    name: 'Frame Five',
    description: 'A frame for dual design, black and white',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameFifteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSixteen = FrameDefinition(
    id: '4by4_frame_sixteen',
    name: 'Frame Six',
    description: 'A frame with a plain navy blue design',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSixteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSeventeen = FrameDefinition(
    id: '4by4_frame_seventeen',
    name: 'Frame Seven',
    description: 'A frame for dual design, black and white',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSeventeen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameEighteen = FrameDefinition(
    id: '4by4_frame_eighteen',
    name: 'Frame Eight',
    description: 'A frame with a scrapbook design.',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameEighteen},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameDinagyang = FrameDefinition(
    id: '4by4_frame_dinagyang',
    name: 'Frame Dinagyang',
    description: 'A limited edition frame for Dinagyang Festival.',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameDinagyang},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameChrome = FrameDefinition(
    id: '4by4_frame_chrome',
    name: 'Frame Chrome',
    description: 'A chrome styled frame',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameChrome},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameDagyangPopup = FrameDefinition(
    id: '4by4_frame_dagyang_popup',
    name: 'Dagyang Popup Frame',
    description: 'A limited edition frame for Dinagyang Festival.',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameDagyangPopup},
    previewWidgetName: 'FourByFourFramePreview',
  );

  static const FrameDefinition fourByFourFrameSouthside = FrameDefinition(
    id: '4by4_frame_southside',
    name: 'Frame Southside',
    description: 'A frame from the Southside',
    supportedLayouts: [FrameLayoutType.fourPhotos],
    layouts: {FrameLayoutType.fourPhotos: fourFrameSouthside},
    previewWidgetName: 'FourByFourFramePreview',
  );

  // 2 by 2

  static const FrameDefinition twoByTwoFrameOne = FrameDefinition(
    id: '2by2_frame_one',
    name: 'Frame One',
    description: 'A classic red 2-by-2 frame.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameOne},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameTwo = FrameDefinition(
    id: '2by2_frame_two',
    name: 'Frame Two',
    description: ' A blue 2-by-2 photo card frame.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameTwo},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameThree = FrameDefinition(
    id: '2by2_frame_three',
    name: 'Frame Three',
    description: 'A cartoon art frame',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameThree},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameFour = FrameDefinition(
    id: '2by2_frame_four',
    name: 'Frame Four',
    description: 'A orange theme graffiti frame',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameFour},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameFive = FrameDefinition(
    id: '2by2_frame_five',
    name: 'Frame Five',
    description: 'A classic white polaroid frame',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameFive},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameSix = FrameDefinition(
    id: '2by2_frame_six',
    name: 'Frame Six',
    description: 'An emoji themed frame',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameSix},
    previewWidgetName: 'TwoByTwoFramePreview',
  );

  static const FrameDefinition twoByTwoFrameSeven = FrameDefinition(
    id: '2by2_frame_seven',
    name: 'Frame Seven',
    description: 'A frame with a JPB design.',
    supportedLayouts: [FrameLayoutType.twoPhotos],
    layouts: {FrameLayoutType.twoPhotos: twoFrameSeven},
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

  static const twoFrameSeven = FrameLayout(
    type: FrameLayoutType.twoPhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 4,
        top: 10,
        width: 145,
        height: 195,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 4,
        top: 256,
        width: 145,
        height: 195,
        rotationDegrees: 0.0,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 159,
        top: 10,
        width: 145,
        height: 195,
        rotationDegrees: 0.0,
      ),
      FramePhotoPosition(
        left: 159,
        top: 256,
        width: 145,
        height: 195,
        rotationDegrees: 0.0,
      ),
    ],
    topOffset: 100,
    frameAssetPath: 'assets/frames/2by2_frame9.png',
  );

  // Landscape Frame Layouts (for landscape mode - rotated 4x4)
  static const landscapeFrameOne = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 20,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 104.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 216,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 20,
        top: 330.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 175,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 104.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 216,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 175,
        top: 330.5,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_one.png',
  );

  static const landscapeFrameTwo = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 14,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 14,
        top: 105,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 14,
        top: 215,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 14,
        top: 326,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 158,
        top: -10,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 158,
        top: 105,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 158,
        top: 215,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 158,
        top: 326,
        width: 110,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_two.png',
  );

  static const landscapeFrameThree = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 18,
        top: -8,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 18,
        top: 104,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 18,
        top: 216,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 18,
        top: 328,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 170,
        top: -8,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 170,
        top: 104,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 170,
        top: 216,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 170,
        top: 328,
        width: 112,
        height: 140,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_three.png',
  );

  static const landscapeFrameFour = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 30,
        top: 2,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 30,
        top: 114,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 30,
        top: 220,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 30,
        top: 329,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 177,
        top: 2,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 177,
        top: 114,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 177,
        top: 220,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 177,
        top: 329,
        width: 108,
        height: 130,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_four.png',
  );

  static const landscapeFrameFive = FrameLayout(
    type: FrameLayoutType.fourLandscapePhotos,
    leftColumnPositions: [
      FramePhotoPosition(
        left: 24,
        top: -20,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 24,
        top: 80,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 24,
        top: 175,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 24,
        top: 277,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
    ],
    rightColumnPositions: [
      FramePhotoPosition(
        left: 178,
        top: -20,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 178,
        top: 80,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 178,
        top: 175,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
      FramePhotoPosition(
        left: 178,
        top: 277,
        width: 102,
        height: 148,
        rotationDegrees: -90,
      ),
    ],
    topOffset: 14,
    frameAssetPath: 'assets/frames/hori_five.png',
  );

  // Landscape Frame Definitions
  static const FrameDefinition landscapeFrameOneDefinition = FrameDefinition(
    id: 'landscape_frame_one',
    name: 'Landscape Frame One',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameOne},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static const FrameDefinition landscapeFrameTwoDefinition = FrameDefinition(
    id: 'landscape_frame_two',
    name: 'Landscape Frame Two',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameTwo},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static const FrameDefinition landscapeFrameThreeDefinition = FrameDefinition(
    id: 'landscape_frame_three',
    name: 'Landscape Frame Three',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameThree},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static const FrameDefinition landscapeFrameFourDefinition = FrameDefinition(
    id: 'landscape_frame_four',
    name: 'Landscape Frame Four',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameFour},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static const FrameDefinition landscapeFrameFiveDefinition = FrameDefinition(
    id: 'landscape_frame_five',
    name: 'Landscape Frame Five',
    description: 'A landscape-oriented 4-photo layout',
    supportedLayouts: [FrameLayoutType.fourLandscapePhotos],
    layouts: {FrameLayoutType.fourLandscapePhotos: landscapeFrameFive},
    previewWidgetName: 'LandscapeFramePreview',
  );

  static List<FrameDefinition> get availableFrames => [
    fourByFourFrameSix,
    fourByFourFrameTwelve,
    fourByFourFrameThirteen,
    fourByFourFrameFourteen,
    fourByFourFrameFifteen,
    fourByFourFrameSixteen,
    fourByFourFrameSeventeen,
    fourByFourFrameChrome,
    twoByTwoFrameOne,
    twoByTwoFrameTwo,
    twoByTwoFrameThree,
    twoByTwoFrameFour,
    twoByTwoFrameFive,
    twoByTwoFrameSix,
    twoByTwoFrameSeven,
    // Add landscape frames
    landscapeFrameOneDefinition,
    landscapeFrameTwoDefinition,
    landscapeFrameThreeDefinition,
    landscapeFrameFourDefinition,
    landscapeFrameFiveDefinition,
  ];
}
