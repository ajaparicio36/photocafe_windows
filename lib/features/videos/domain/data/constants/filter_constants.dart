class VideoFilterConstants {
  // Video dimensions with 16:9 aspect ratio for proper frame extraction
  // Using 16:9 to prevent image elongation in flipbook frames
  static const int videoWidth = 1920;
  static const int videoHeight = 1080;

  // 16:9 aspect ratio constant
  static const double aspectRatio = 16 / 9;

  // Filter names
  static const String noFilterName = 'No Filter';
  static const String vintageFilterName = 'Vintage';
  static const String blackAndWhiteFilterName = 'Black & White';
  static const String sepiaFilterName = 'Sepia';
  static const String brightnessFilterName = 'Bright';
  static const String contrastFilterName = 'High Contrast';

  static const List<String> availableFilters = [
    noFilterName,
    vintageFilterName,
    blackAndWhiteFilterName,
    sepiaFilterName,
    brightnessFilterName,
    contrastFilterName,
  ];

  static List<String> getFilterArgs(String filterName) {
    switch (filterName) {
      case noFilterName:
        return [];
      case vintageFilterName:
        return [
          'eq=contrast=1.1:brightness=0.1:saturation=0.8',
          // Removed 'curves=vintage' as it may not be available in all FFmpeg builds
          // Using color adjustments instead for vintage effect
          'colorchannelmixer=rr=1.0:rg=0.1:rb=0.0:gr=0.0:gg=0.9:gb=0.0:br=0.2:bg=0.1:bb=0.8',
        ];
      case blackAndWhiteFilterName:
        return ['hue=s=0'];
      case sepiaFilterName:
        return [
          'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
        ];
      case brightnessFilterName:
        return ['eq=brightness=0.2:contrast=1.1'];
      case contrastFilterName:
        return ['eq=contrast=1.4:brightness=0.05'];
      default:
        return [];
    }
  }
}
