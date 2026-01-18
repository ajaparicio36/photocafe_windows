import 'package:image/image.dart' as img;

class FilterDefinition {
  final String id;
  final String name;
  final String description;
  final img.Image Function(img.Image) applyFilter;

  const FilterDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.applyFilter,
  });
}

class FilterConstants {
  static const String noFilterName = 'No Filter';
  static const String vintageFilterName = 'Vintage Sepia';
  static const String hdrFilterName = 'HDR Boost';
  static const String matteFilterName = 'Matte Fade';
  static const String vscoA6FilterName = 'VSCO A6 Warm';
  static const String blackWhiteFilterName = 'Mono B1';
  static const String cinematicFilterName = 'Cinematic Teal‑Orange';

  // Vintage Sepia: warm sepia tone
  static img.Image applyVintageFilter(img.Image image) {
    var filtered = img.adjustColor(
      image,
      brightness: 1.05,
      contrast: 1.1,
      saturation: 0.8,
    );
    var result = img.Image.from(filtered);

    // Apply sepia tone
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        // Properly clamp input values first to handle any out-of-range pixels
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        // Sepia transformation with proper double arithmetic
        final newR = (r * 0.393 + g * 0.769 + b * 0.189).round().clamp(0, 255);
        final newG = (r * 0.349 + g * 0.686 + b * 0.168).round().clamp(0, 255);
        final newB = (r * 0.272 + g * 0.534 + b * 0.131).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
    return result;
  }

  // HDR Boost: increase dynamic range, mid-tone contrast, clarity
  static img.Image applyHdrFilter(img.Image image) {
    return img.adjustColor(image, contrast: 1.2, brightness: 1.05);
  }

  // Matte Fade: low contrast, slight fade
  static img.Image applyMatteFilter(img.Image image) {
    return img.adjustColor(image, contrast: 0.85, brightness: 1.1);
  }

  // VSCO A6 Warm: warm tone with subtle brightness boost
  static img.Image applyVscoA6Filter(img.Image image) {
    // Use gentler values to prevent bright areas from clipping to black
    var filtered = img.adjustColor(
      image,
      brightness: 1.08,
      contrast: 1.08,
      saturation: 1.15,
    );

    // Apply subtle warm toning without risking overflow
    var result = img.Image.from(filtered);
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        // Subtle warm shift - add slight red/yellow, reduce blue slightly
        final newR = (r + 5).clamp(0, 255);
        final newG = (g + 2).clamp(0, 255);
        final newB = (b - 8).clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
    return result;
  }

  // Mono B1: black & white with rich contrast
  static img.Image applyMonoFilter(img.Image image) {
    var filtered = img.grayscale(image);
    return img.adjustColor(filtered, contrast: 1.3);
  }

  // Cinematic Teal-Orange: manual teal-orange effect
  static img.Image applyCinematicFilter(img.Image image) {
    // Use gentler contrast to prevent clipping
    var filtered = img.adjustColor(image, contrast: 1.15, saturation: 1.08);
    var result = img.Image.from(filtered);

    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        // Properly convert to int and clamp input values first
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        // Push highlights toward orange, shadows toward teal
        final luminance = (r + g + b) / 3.0;
        final factor = (luminance / 255.0).clamp(0.0, 1.0);

        // Use gentler color shifts to prevent artifacts
        final newR = (r + factor * 15).round().clamp(0, 255);
        final newG = (g + factor * 8 - (1 - factor) * 8).round().clamp(0, 255);
        final newB = (b - factor * 8 + (1 - factor) * 15).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
    return result;
  }

  static List<String> get availableFilters => [
    noFilterName,
    vintageFilterName,
    hdrFilterName,
    matteFilterName,
    vscoA6FilterName,
    blackWhiteFilterName,
    cinematicFilterName,
  ];

  // Filter Definitions with descriptions
  static final List<FilterDefinition> filterDefinitions = [
    FilterDefinition(
      id: 'no_filter',
      name: noFilterName,
      description: 'Keep your photos as they are',
      applyFilter: (img.Image image) => image,
    ),
    FilterDefinition(
      id: 'vintage_sepia',
      name: vintageFilterName,
      description: 'Add a classic vintage look with warm tones',
      applyFilter: applyVintageFilter,
    ),
    FilterDefinition(
      id: 'hdr_boost',
      name: hdrFilterName,
      description: 'Enhance details and vibrancy in your photos',
      applyFilter: applyHdrFilter,
    ),
    FilterDefinition(
      id: 'matte_fade',
      name: matteFilterName,
      description: 'Lower contrast filter, make your photos cinematic',
      applyFilter: applyMatteFilter,
    ),
    FilterDefinition(
      id: 'vsco_a6',
      name: vscoA6FilterName,
      description: 'Add a gentle warmth for an analog-inspired photo',
      applyFilter: applyVscoA6Filter,
    ),
    FilterDefinition(
      id: 'mono_b1',
      name: blackWhiteFilterName,
      description: 'Get your photos in black and white, a timeless touch',
      applyFilter: applyMonoFilter,
    ),
    FilterDefinition(
      id: 'cinematic',
      name: cinematicFilterName,
      description: 'Cinematic teal and orange look',
      applyFilter: applyCinematicFilter,
    ),
  ];
}
