enum FlipbookFrameType { singleFrame, doubleFrame }

class FlipbookFramePosition {
  final double left;
  final double top;
  final double width;
  final double height;

  const FlipbookFramePosition({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class FlipbookFrameLayout {
  final double pageWidth;
  final double pageHeight;
  final bool isLandscape;
  final String frameAssetPath;
  final List<FlipbookFramePosition> framePositions;

  const FlipbookFrameLayout({
    required this.pageWidth,
    required this.pageHeight,
    required this.isLandscape,
    required this.frameAssetPath,
    required this.framePositions,
  });
}

class FlipbookFrameDefinition {
  final String id;
  final String name;
  final String description;
  final String previewWidgetName;
  final FlipbookFrameLayout layout;

  const FlipbookFrameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.previewWidgetName,
    required this.layout,
  });
}

class FlipbookFrameConstants {
  // A6 landscape dimensions in points (1 point = 1/72 inch)
  // A6 = 105 × 148 mm = 297.6 × 419.5 points
  // Landscape = 419.5 × 297.6 points
  static const double a6LandscapeWidth = 419.5;
  static const double a6LandscapeHeight = 297.6;

  // Standard Flipbook Frame Layout - A6 Landscape
  static const flipbookFrameOne = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame1.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(
        left: 215.0,
        top: 22.0,
        width: 220, // pageWidth - 40 (20px margins on each side)
        height: 248, // pageHeight - 40 (20px margins on each side)
      ),
    ],
  );

  static const flipbookFrameTwo = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame2.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(left: 215.0, top: 25.0, width: 210, height: 238),
    ],
  );

  static const flipbookFrameThree = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame3.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(left: 200.0, top: 18.0, width: 228, height: 258),
    ],
  );

  static const flipbookFrameFour = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame4.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(left: 215, top: 20.0, width: 220, height: 248),
    ],
  );

  static const flipbookFrameFive = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame5.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(left: 200, top: 18.0, width: 232, height: 262),
    ],
  );

  static const flipbookFrameSix = FlipbookFrameLayout(
    pageWidth: a6LandscapeWidth,
    pageHeight: a6LandscapeHeight,
    isLandscape: true,
    frameAssetPath: 'assets/flipbook/frame6.png',
    framePositions: [
      // Frame position for A6 landscape
      FlipbookFramePosition(left: 210, top: 16, width: 220, height: 262),
    ],
  );

  // Frame Definitions with proper A6 landscape layouts
  static const FlipbookFrameDefinition frameOne = FlipbookFrameDefinition(
    id: 'standard_frame',
    name: 'Frame One',
    description: 'A classic flipbook frame with decorative borders.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameOne,
  );

  static const FlipbookFrameDefinition frameTwo = FlipbookFrameDefinition(
    id: 'frame_two',
    name: 'Frame Two',
    description: 'A modern flipbook frame with a sleek design.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameTwo,
  );

  static const FlipbookFrameDefinition frameThree = FlipbookFrameDefinition(
    id: 'frame_three',
    name: 'Frame Three',
    description: 'A playful flipbook frame with vibrant colors.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameThree,
  );

  static const FlipbookFrameDefinition frameFour = FlipbookFrameDefinition(
    id: 'frame_four',
    name: 'Frame Four',
    description: 'A minimalist flipbook frame with clean lines.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameFour,
  );

  static const FlipbookFrameDefinition frameFive = FlipbookFrameDefinition(
    id: 'frame_five',
    name: 'Frame Five',
    description: 'A vintage flipbook frame with ornate details.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameFive,
  );

  static const FlipbookFrameDefinition frameSix = FlipbookFrameDefinition(
    id: 'frame_six',
    name: 'Frame Six',
    description: 'A futuristic flipbook frame with neon accents.',
    previewWidgetName: 'StandardFlipbookFrame',
    layout: flipbookFrameSix,
  );

  static List<FlipbookFrameDefinition> get availableFrames => [
    frameOne,
    frameTwo,
    frameThree,
    frameFour,
    frameFive,
    frameSix,
  ];
}
