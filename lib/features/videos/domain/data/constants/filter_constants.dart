class VideoFilterConstants {
  // A6 landscape video dimensions (16:10 aspect ratio optimized for A6)
  // A6 landscape is 419.5 × 297.6 points, so we use proportional video size
  static const int videoWidth = 1600;
  static const int videoHeight = 1000;

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
          'curves=vintage',
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
