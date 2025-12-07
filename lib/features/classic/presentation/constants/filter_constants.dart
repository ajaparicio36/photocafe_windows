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
  static const String lomoFilterName = 'Lomo Pop';
  static const String duotoneFilterName = 'Duotone Teal‑Orange';
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
        var r = pixel.r;
        var g = pixel.g;
        var b = pixel.b;

        // Sepia transformation
        var newR = ((r * 0.393) + (g * 0.769) + (b * 0.189))
            .clamp(0, 255)
            .round();
        var newG = ((r * 0.349) + (g * 0.686) + (b * 0.168))
            .clamp(0, 255)
            .round();
        var newB = ((r * 0.272) + (g * 0.534) + (b * 0.131))
            .clamp(0, 255)
            .round();

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

  // Lomo Pop: high contrast, saturated
  static img.Image applyLomoFilter(img.Image image) {
    return img.adjustColor(image, saturation: 1.4, contrast: 1.3);
  }

  // Duotone Teal-Orange: manual duotone effect
  static img.Image applyDuotoneFilter(img.Image image) {
    var filtered = img.grayscale(image);
    var result = img.Image.from(filtered);

    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        var luminance = img.getLuminance(pixel) / 255.0;

        // Teal for shadows, orange for highlights
        var r = (luminance * 255 + (1 - luminance) * 0).round();
        var g = (luminance * 128 + (1 - luminance) * 128).round();
        var b = (luminance * 0 + (1 - luminance) * 128).round();

        result.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
    return result;
  }

  // VSCO A6 Warm: warm tone with subtle brightness boost
  static img.Image applyVscoA6Filter(img.Image image) {
    return img.adjustColor(
      image,
      brightness: 1.1,
      contrast: 1.1,
      saturation: 1.2,
    );
  }

  // Mono B1: black & white with rich contrast
  static img.Image applyMonoFilter(img.Image image) {
    var filtered = img.grayscale(image);
    return img.adjustColor(filtered, contrast: 1.3);
  }

  // Cinematic Teal-Orange: manual teal-orange effect
  static img.Image applyCinematicFilter(img.Image image) {
    var filtered = img.adjustColor(image, contrast: 1.2, saturation: 1.1);
    var result = img.Image.from(filtered);

    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        var r = pixel.r;
        var g = pixel.g;
        var b = pixel.b;

        // Push highlights toward orange, shadows toward teal
        var luminance = (r + g + b) / 3;
        var factor = luminance / 255.0;

        r = (r + factor * 20).clamp(0, 255).round().toInt();
        g = (g + factor * 10 - (1 - factor) * 10).clamp(0, 255).round().toInt();
        b = (b - factor * 10 + (1 - factor) * 20).clamp(0, 255).round().toInt();

        result.setPixel(x, y, img.ColorRgb8(r.toInt(), g.toInt(), b.toInt()));
      }
    }
    return result;
  }

  static List<String> get availableFilters => [
    // noFilterName,
    // vintageFilterName,
    hdrFilterName,
    // matteFilterName,
    // lomoFilterName,
    // duotoneFilterName,
    // vscoA6FilterName,
    blackWhiteFilterName,
    // cinematicFilterName,
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
      id: 'lomo_pop',
      name: lomoFilterName,
      description: 'High contrast and saturated colors',
      applyFilter: applyLomoFilter,
    ),
    FilterDefinition(
      id: 'duotone',
      name: duotoneFilterName,
      description: 'Artistic duotone effect',
      applyFilter: applyDuotoneFilter,
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
