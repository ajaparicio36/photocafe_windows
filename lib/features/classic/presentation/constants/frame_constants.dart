enum FrameLayoutType { twoPhotos, fourPhotos }

class FrameDefinition {
  final String id;
  final String name;
  final String description;
  final List<FrameLayoutType> supportedLayouts;

  const FrameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.supportedLayouts,
  });
}

class FrameConstants {
  static const FrameDefinition classicFrame = FrameDefinition(
    id: 'frame_one',
    name: 'Classic Frame',
    description: 'A decorative strip layout.',
    supportedLayouts: [FrameLayoutType.twoPhotos, FrameLayoutType.fourPhotos],
  );

  static List<FrameDefinition> get availableFrames => [classicFrame];
}
