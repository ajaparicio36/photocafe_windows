class VideoFilterConstants {
  static const String noFilterName = 'No Filter';
  static const String vintageFilterName = 'Vintage Film';
  static const String vhsFilterName = 'VHS Retro';

  // 16:10 aspect ratio dimensions
  static const int videoWidth = 800;
  static const int videoHeight = 500;

  static List<String> get availableFilters => [
    noFilterName,
    vintageFilterName,
    vhsFilterName,
  ];

  static List<String> getFilterArgs(String filterName) {
    switch (filterName) {
      case vintageFilterName:
        return [
          'scale=${videoWidth}:${videoHeight}',
          'eq=contrast=1.3:brightness=0.05:saturation=1.2',
          'noise=alls=8:allf=t',
          'curves=vintage',
        ];
      case vhsFilterName:
        return [
          'scale=${videoWidth}:${videoHeight}',
          'fps=25',
          'noise=alls=10:allf=t',
          'eq=contrast=1.3:brightness=0.05:saturation=1.4',
          'unsharp=5:5:1.0:5:5:0.0',
        ];
      default:
        return ['scale=${videoWidth}:${videoHeight}'];
    }
  }

  static String get aspectRatio => '${videoWidth}:${videoHeight}';
}
