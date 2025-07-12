import 'package:image/image.dart' as img;

class FilterConstants {
  static const String vintageFilterName = 'Vintage Sepia';

  static img.Image applyVintageFilter(img.Image image) {
    // Apply sepia effect
    img.Image filtered = img.sepia(image);

    // Reduce saturation slightly for vintage look
    filtered = img.adjustColor(filtered, saturation: 0.8);

    // Add slight contrast
    filtered = img.adjustColor(filtered, contrast: 1.1);

    // Add slight brightness reduction
    filtered = img.adjustColor(filtered, brightness: 0.95);

    return filtered;
  }

  static List<String> get availableFilters => [vintageFilterName];
}
