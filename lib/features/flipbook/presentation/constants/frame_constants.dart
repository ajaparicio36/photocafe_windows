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
  static const standardFrameLayout = FlipbookFrameLayout(
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

  // Vintage Flipbook Frame Layout
  static const vintageFrameLayout = FlipbookFrameLayout(
    type: FlipbookFrameType.doubleFrame,
    framePositions: [
      // First frame position (slightly different positioning)
      FlipbookFramePosition(
        left: 210.0,
        top: 15.0,
        width: 180.0,
        height: 120.0,
      ),
      // Second frame position
      FlipbookFramePosition(
        left: 210.0,
        top: 15.0,
        width: 180.0,
        height: 120.0,
      ),
    ],
    frameAssetPath: 'assets/flipbook/vintage_frame.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  // Minimal Flipbook Frame Layout
  static const minimalFrameLayout = FlipbookFrameLayout(
    type: FlipbookFrameType.doubleFrame,
    framePositions: [
      // First frame position
      FlipbookFramePosition(left: 200.0, top: 5.0, width: 210.0, height: 135.0),
      // Second frame position
      FlipbookFramePosition(left: 200.0, top: 5.0, width: 210.0, height: 135.0),
    ],
    frameAssetPath: 'assets/flipbook/minimal_frame.png',
    pageWidth: 420.0,
    pageHeight: 149.0,
    isLandscape: true,
  );

  // Frame Definitions
  static const FlipbookFrameDefinition standardFrame = FlipbookFrameDefinition(
    id: 'standard_frame',
    name: 'Standard Frame',
    description: 'A classic flipbook frame with decorative borders.',
    layout: standardFrameLayout,
    previewWidgetName: 'StandardFlipbookFrame',
  );

  static const FlipbookFrameDefinition vintageFrame = FlipbookFrameDefinition(
    id: 'vintage_frame',
    name: 'Vintage Frame',
    description: 'A retro-style frame with ornate details.',
    layout: vintageFrameLayout,
    previewWidgetName: 'VintageFlipbookFrame',
  );

  static const FlipbookFrameDefinition minimalFrame = FlipbookFrameDefinition(
    id: 'minimal_frame',
    name: 'Minimal Frame',
    description: 'A clean, modern frame with minimal decoration.',
    layout: minimalFrameLayout,
    previewWidgetName: 'MinimalFlipbookFrame',
  );

  // TODO: Add more frames here as needed
  // static const FlipbookFrameDefinition funFrame = FlipbookFrameDefinition(
  //   id: 'fun_frame',
  //   name: 'Fun Frame',
  //   description: 'A playful frame with bright colors.',
  //   layout: funFrameLayout,
  //   previewWidgetName: 'FunFlipbookFrame',
  // );

  static List<FlipbookFrameDefinition> get availableFrames => [
    standardFrame,
    vintageFrame,
    minimalFrame,
    // funFrame, // Add more frames here
  ];
}
