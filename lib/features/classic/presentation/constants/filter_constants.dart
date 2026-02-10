import 'dart:math' as math;
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
  // static const String matteFilterName = 'Matte Fade';
  // static const String vscoA6FilterName = 'VSCO A6 Warm';
  static const String blackWhiteFilterName = 'Mono B1';
  // static const String cinematicFilterName = 'Cinematic Teal‑Orange';
  static const String photoboothFilterName = 'Photobooth';

  /// Safely clamp a number to [0, 255] and convert to int.
  /// Use this EVERYWHERE before passing values to ColorRgb8 to prevent
  /// Uint8List wrapping (e.g. 260 → 4 instead of 255).
  static int _clamp8(num value) => value.round().clamp(0, 255).toInt();

  /// Construct a ColorRgb8 with guaranteed-safe clamped values.
  static img.ColorRgb8 _safeColor(num r, num g, num b) =>
      img.ColorRgb8(_clamp8(r), _clamp8(g), _clamp8(b));

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
        final newR = r * 0.393 + g * 0.769 + b * 0.189;
        final newG = r * 0.349 + g * 0.686 + b * 0.168;
        final newB = r * 0.272 + g * 0.534 + b * 0.131;

        result.setPixel(x, y, _safeColor(newR, newG, newB));
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
        final newR = r + 5;
        final newG = g + 2;
        final newB = b - 8;

        result.setPixel(x, y, _safeColor(newR, newG, newB));
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
        final newR = r + factor * 15;
        final newG = g + factor * 8 - (1 - factor) * 8;
        final newB = b - factor * 8 + (1 - factor) * 15;

        result.setPixel(x, y, _safeColor(newR, newG, newB));
      }
    }
    return result;
  }

  // Photobooth: classic photobooth film aesthetic
  // Warm near-monochrome, lifted matte blacks, punchy midtone contrast, cream highlights
  static img.Image applyPhotoboothFilter(img.Image image) {
    // Step 1: Desaturate heavily but keep a ghost of color for warmth
    var filtered = img.adjustColor(
      image,
      saturation: 0.12,
      contrast: 1.25,
      brightness: 1.02,
    );

    var result = img.Image.from(filtered);
    final cx = result.width / 2.0;
    final cy = result.height / 2.0;
    final maxDist = (cx * cx + cy * cy);

    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        var r = pixel.r.toInt().clamp(0, 255);
        var g = pixel.g.toInt().clamp(0, 255);
        var b = pixel.b.toInt().clamp(0, 255);

        // Step 2: Lift blacks — raise the floor so shadows stay matte
        // Map [0-255] → [18-255] to prevent pure black
        r = _clamp8(18 + (r * 237 / 255));
        g = _clamp8(18 + (g * 237 / 255));
        b = _clamp8(18 + (b * 237 / 255));

        // Step 3: Apply warm cream tone
        // Shadows get a subtle warm brown, highlights get a cream/ivory push
        final lum = (r * 0.299 + g * 0.587 + b * 0.114);
        final lumNorm = (lum / 255.0).clamp(0.0, 1.0);

        // Warm shadow toning (slight brown)
        final shadowR = _clamp8(r + (1.0 - lumNorm) * 8);
        final shadowG = _clamp8(g + (1.0 - lumNorm) * 3);
        final shadowB = _clamp8(b - (1.0 - lumNorm) * 6);

        // Cream highlight toning (warm ivory)
        r = _clamp8(shadowR + lumNorm * 10);
        g = _clamp8(shadowG + lumNorm * 7);
        b = _clamp8(shadowB - lumNorm * 4);

        // Step 4: S-curve for midtone punch
        // True sigmoid S-curve: pushes midtones apart for that contrasty film pop
        r = _sCurve(r);
        g = _sCurve(g);
        b = _sCurve(b);

        // Step 5: Subtle vignette — darken edges naturally
        final dx = x - cx;
        final dy = y - cy;
        final distSq = dx * dx + dy * dy;
        final vignette = 1.0 - (distSq / maxDist) * 0.35;

        result.setPixel(
          x,
          y,
          _safeColor(r * vignette, g * vignette, b * vignette),
        );
      }
    }
    return result;
  }

  /// S-curve tone mapping for midtone contrast punch.
  /// Uses a true sigmoid function that is mathematically bounded to [0, 1],
  /// so it can never overshoot into overflow territory.
  static int _sCurve(int value) {
    final n = value / 255.0;
    // True sigmoid: 1 / (1 + e^(-k*(x-0.5)))
    // k controls steepness; k=5.5 gives a natural film-like midtone punch
    // without crushing highlights or shadows
    final curved = 1.0 / (1.0 + math.exp(-5.5 * (n - 0.5)));
    // Blend 60% sigmoid with 40% linear to keep a natural feel
    final blended = curved * 0.6 + n * 0.4;
    return _clamp8(blended * 255);
  }

  static List<String> get availableFilters => [
    noFilterName,
    vintageFilterName,
    hdrFilterName,
    // matteFilterName,
    // vscoA6FilterName,
    blackWhiteFilterName,
    // cinematicFilterName,
    photoboothFilterName,
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
    // FilterDefinition(
    //   id: 'matte_fade',
    //   name: matteFilterName,
    //   description: 'Lower contrast filter, make your photos cinematic',
    //   applyFilter: applyMatteFilter,
    // ),
    // FilterDefinition(
    //   id: 'vsco_a6',
    //   name: vscoA6FilterName,
    //   description: 'Add a gentle warmth for an analog-inspired photo',
    //   applyFilter: applyVscoA6Filter,
    // ),
    FilterDefinition(
      id: 'mono_b1',
      name: blackWhiteFilterName,
      description: 'Get your photos in black and white, a timeless touch',
      applyFilter: applyMonoFilter,
    ),
    // FilterDefinition(
    //   id: 'cinematic',
    //   name: cinematicFilterName,
    //   description: 'Cinematic teal and orange look',
    //   applyFilter: applyCinematicFilter,
    // ),
    FilterDefinition(
      id: 'photobooth',
      name: photoboothFilterName,
      description:
          'Classic photobooth film look with warm tones and matte finish',
      applyFilter: applyPhotoboothFilter,
    ),
  ];
}
