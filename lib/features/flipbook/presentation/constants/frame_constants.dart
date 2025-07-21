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
  final FlipbookFrameType type;
  final List<FlipbookFramePosition> framePositions;
  final String frameAssetPath;
  final double pageWidth;
  final double pageHeight;
  final bool isLandscape;

  const FlipbookFrameLayout({
    required this.type,
    required this.framePositions,
    required this.frameAssetPath,
    required this.pageWidth,
    required this.pageHeight,
    required this.isLandscape,
  });
}

class FlipbookFrameDefinition {
  final String id;
  final String name;
  final String description;
  final FlipbookFrameLayout layout;
  final String previewWidgetName;

  const FlipbookFrameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.layout,
    required this.previewWidgetName,
  });
}

class FlipbookFrameConstants {
  // Standard Flipbook Frame Layout
  static const flipbookFrameOne = FlipbookFrameLayout(
    type: FlipbookFrameType.doubleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(
        left: 220.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 220.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/frame1.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  static const flipbookFrameTwo = FlipbookFrameLayout(
    type: FlipbookFrameType.singleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(
        left: 213.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 213.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/frame2.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  static const flipbookFrameThree = FlipbookFrameLayout(
    type: FlipbookFrameType.doubleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(
        left: 208.0,
        top: 10.0,
        width: 205.0,
        height: 140.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 208.0,
        top: 10.0,
        width: 205.0,
        height: 140.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/frame3.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  static const flipbookFrameFour = FlipbookFrameLayout(
    type: FlipbookFrameType.singleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(
        left: 220.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 220.0,
        top: 10.0,
        width: 195.0,
        height: 140.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/frame4.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  static const flipbookFrameFive = FlipbookFrameLayout(
    type: FlipbookFrameType.doubleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(
        left: 208.0,
        top: 10.0,
        width: 205.0,
        height: 140.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 208.0,
        top: 10.0,
        width: 205.0,
        height: 140.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/frame5.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  static const flipbookFrameSix = FlipbookFrameLayout(
    type: FlipbookFrameType.singleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(left: 208.0, top: 8.0, width: 205.0, height: 142.0),
      // Second frame position
      FlipbookFramePosition(left: 208.0, top: 8.0, width: 205.0, height: 142.0),
    ],
    frameAssetPath: 'assets/flipbook/frame6.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  // Frame Definitions
  static const FlipbookFrameDefinition frameOne = FlipbookFrameDefinition(
    id: 'standard_frame',
    name: 'Frame One',
    description: 'A classic flipbook frame with decorative borders.',
    layout: flipbookFrameOne,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition frameTwo = FlipbookFrameDefinition(
    id: 'frame_two',
    name: 'Frame Two',
    description: 'A modern flipbook frame with a sleek design.',
    layout: flipbookFrameTwo,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition frameThree = FlipbookFrameDefinition(
    id: 'frame_three',
    name: 'Frame Three',
    description: 'A playful flipbook frame with vibrant colors.',
    layout: flipbookFrameThree,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition frameFour = FlipbookFrameDefinition(
    id: 'frame_four',
    name: 'Frame Four',
    description: 'A minimalist flipbook frame with clean lines.',
    layout: flipbookFrameFour,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition frameFive = FlipbookFrameDefinition(
    id: 'frame_five',
    name: 'Frame Five',
    description: 'A vintage flipbook frame with ornate details.',
    layout: flipbookFrameFive,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition frameSix = FlipbookFrameDefinition(
    id: 'frame_six',
    name: 'Frame Six',
    description: 'A futuristic flipbook frame with neon accents.',
    layout: flipbookFrameSix,
    previewWidgetName: 'StandardFlipbookFrame',
  );
  static List<FlipbookFrameDefinition> get availableFrames => [
    frameOne,
    frameTwo,
    frameThree,
    frameFour,
    frameFive,
    frameSix,
    // funFrame, // Add more frames here
  ];
}
