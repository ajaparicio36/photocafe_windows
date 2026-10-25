import 'dart:math';

enum KioskProduct { classic, keychain, flipbook }

enum ClassicVariant { portrait, landscape, photobox }

enum KioskMode {
  classicPortrait,
  classicLandscape,
  classicPhotobox,
  keychain,
  flipbook,
}

enum FrameTemplateKind {
  classicPortrait,
  classicLandscape,
  classicPhotobox,
  flipbook,
}

class FrameCatalogException implements Exception {
  final String message;
  const FrameCatalogException(this.message);
  @override
  String toString() => message;
}

String newFrameId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0x7fffffff).toRadixString(36)}';

class FrameSlot {
  final String id;

  /// Classic source photo (0–3); Flipbook 0 means the current sequence image.
  final int photoIndex;
  final double left, top, width, height, rotationDegrees;
  const FrameSlot({
    required this.id,
    required this.photoIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
  });
  FrameSlot copyWith({
    String? id,
    int? photoIndex,
    double? left,
    double? top,
    double? width,
    double? height,
    double? rotationDegrees,
  }) => FrameSlot(
    id: id ?? this.id,
    photoIndex: photoIndex ?? this.photoIndex,
    left: left ?? this.left,
    top: top ?? this.top,
    width: width ?? this.width,
    height: height ?? this.height,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'photoIndex': photoIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'rotationDegrees': rotationDegrees,
  };
  factory FrameSlot.fromJson(Object? value) {
    final map = jsonMap(value);
    return FrameSlot(
      id: jsonString(map, 'id'),
      photoIndex: jsonInt(map, 'photoIndex'),
      left: jsonDouble(map, 'left'),
      top: jsonDouble(map, 'top'),
      width: jsonDouble(map, 'width'),
      height: jsonDouble(map, 'height'),
      rotationDegrees: jsonDouble(map, 'rotationDegrees'),
    );
  }
}

class FrameArtwork {
  /// A bundled asset key, or an owned path relative to the catalog directory.
  final String path;
  final bool isBundled;
  final int pixelWidth, pixelHeight;
  const FrameArtwork({
    required this.path,
    required this.isBundled,
    required this.pixelWidth,
    required this.pixelHeight,
  });
  Map<String, Object?> toJson() => {
    'path': path,
    'isBundled': isBundled,
    'pixelWidth': pixelWidth,
    'pixelHeight': pixelHeight,
  };
  factory FrameArtwork.fromJson(Object? value) {
    final map = jsonMap(value);
    return FrameArtwork(
      path: jsonString(map, 'path'),
      isBundled: jsonBool(map, 'isBundled'),
      pixelWidth: jsonInt(map, 'pixelWidth'),
      pixelHeight: jsonInt(map, 'pixelHeight'),
    );
  }
}

class FrameTemplate {
  final String id, name;
  final int revision;
  final FrameTemplateKind kind;
  final FrameArtwork artwork;
  final List<FrameSlot> slots;
  final bool enabled, bundled;
  FrameTemplate({
    required this.id,
    required this.name,
    required this.revision,
    required this.kind,
    required this.artwork,
    required List<FrameSlot> slots,
    required this.enabled,
    required this.bundled,
  }) : slots = List.unmodifiable(slots);
  factory FrameTemplate.create({
    required FrameTemplateKind kind,
    required String name,
    required FrameArtwork artwork,
  }) => FrameTemplate(
    id: 'custom-${newFrameId()}',
    name: name,
    revision: 1,
    kind: kind,
    artwork: artwork,
    slots: [
      FrameSlot(
        id: newFrameId(),
        photoIndex: 0,
        left: 20,
        top: 20,
        width: 120,
        height: 100,
      ),
    ],
    enabled: false,
    bundled: false,
  );
  double get canvasWidth => kind == FrameTemplateKind.flipbook ? 432 : 297.6;
  double get canvasHeight => kind == FrameTemplateKind.flipbook ? 288 : 442.56;
  Set<KioskMode> get compatibleModes => switch (kind) {
    FrameTemplateKind.classicPortrait => const {
      KioskMode.classicPortrait,
      KioskMode.keychain,
    },
    FrameTemplateKind.classicLandscape => const {KioskMode.classicLandscape},
    FrameTemplateKind.classicPhotobox => const {KioskMode.classicPhotobox},
    FrameTemplateKind.flipbook => const {KioskMode.flipbook},
  };
  FrameTemplate copyWith({
    String? id,
    String? name,
    int? revision,
    FrameTemplateKind? kind,
    FrameArtwork? artwork,
    List<FrameSlot>? slots,
    bool? enabled,
    bool? bundled,
  }) => FrameTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    revision: revision ?? this.revision,
    kind: kind ?? this.kind,
    artwork: artwork ?? this.artwork,
    slots: slots ?? this.slots,
    enabled: enabled ?? this.enabled,
    bundled: bundled ?? this.bundled,
  );
  void validate() {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 100 ||
        revision < 1 ||
        slots.isEmpty ||
        slots.length > 32) {
      throw const FrameCatalogException(
        'A frame needs a name and between 1 and 32 photo slots.',
      );
    }
    if (slots.map((s) => s.id).toSet().length != slots.length) {
      throw const FrameCatalogException('Photo slot IDs must be unique.');
    }
    for (final slot in slots) {
      final geometry = [
        slot.left,
        slot.top,
        slot.width,
        slot.height,
        slot.rotationDegrees,
      ];
      if (slot.id.isEmpty ||
          slot.id.length > 100 ||
          geometry.any((v) => !v.isFinite || v.abs() > 10000) ||
          slot.width <= 0 ||
          slot.height <= 0 ||
          slot.width > canvasWidth * 4 ||
          slot.height > canvasHeight * 4 ||
          slot.left.abs() > canvasWidth * 4 ||
          slot.top.abs() > canvasHeight * 4 ||
          slot.rotationDegrees.abs() > 360 ||
          slot.photoIndex < 0 ||
          slot.photoIndex > (kind == FrameTemplateKind.flipbook ? 0 : 3)) {
        throw const FrameCatalogException(
          'Photo slots need finite, bounded geometry and a valid source photo.',
        );
      }
    }
    if (artwork.path.isEmpty ||
        artwork.pixelWidth < 1 ||
        artwork.pixelHeight < 1 ||
        artwork.pixelWidth > 8192 ||
        artwork.pixelHeight > 8192 ||
        artwork.pixelWidth * artwork.pixelHeight > 32000000) {
      throw const FrameCatalogException(
        'Artwork dimensions are invalid or too large.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'revision': revision,
    'kind': kind.name,
    'artwork': artwork.toJson(),
    'slots': slots.map((s) => s.toJson()).toList(),
    'enabled': enabled,
    'bundled': bundled,
  };
  factory FrameTemplate.fromJson(Object? value) {
    final map = jsonMap(value);
    final template = FrameTemplate(
      id: jsonString(map, 'id'),
      name: jsonString(map, 'name'),
      revision: jsonInt(map, 'revision'),
      kind: FrameTemplateKind.values.byName(jsonString(map, 'kind')),
      artwork: FrameArtwork.fromJson(map['artwork']),
      slots: jsonList(map['slots']).map(FrameSlot.fromJson).toList(),
      enabled: jsonBool(map, 'enabled'),
      bundled: jsonBool(map, 'bundled'),
    );
    template.validate();
    return template;
  }
}

class FrameCatalog {
  final List<FrameTemplate> templates;
  final Set<KioskProduct> enabledProducts;
  final Set<ClassicVariant> enabledClassicVariants;
  final String? warning;
  FrameCatalog({
    required List<FrameTemplate> templates,
    required Set<KioskProduct> enabledProducts,
    required Set<ClassicVariant> enabledClassicVariants,
    this.warning,
  }) : templates = List.unmodifiable(templates),
       enabledProducts = Set.unmodifiable(enabledProducts),
       enabledClassicVariants = Set.unmodifiable(enabledClassicVariants);
  List<FrameTemplate> customerFrames(KioskMode mode) => List.unmodifiable(
    templates.where((t) => t.enabled && t.compatibleModes.contains(mode)),
  );
  FrameTemplate byId(String id) => templates.firstWhere(
    (t) => t.id == id,
    orElse: () => throw const FrameCatalogException(
      'This frame no longer exists. Reopen the catalog.',
    ),
  );
  bool isModeUsable(KioskMode mode) {
    final product = productForMode(mode);
    final variant = variantForMode(mode);
    return enabledProducts.contains(product) &&
        (variant == null || enabledClassicVariants.contains(variant)) &&
        customerFrames(mode).isNotEmpty;
  }

  bool isProductUsable(KioskProduct product) => KioskMode.values.any(
    (mode) => productForMode(mode) == product && isModeUsable(mode),
  );
  FrameCatalog copyWith({
    List<FrameTemplate>? templates,
    Set<KioskProduct>? enabledProducts,
    Set<ClassicVariant>? enabledClassicVariants,
    String? warning,
  }) => FrameCatalog(
    templates: templates ?? this.templates,
    enabledProducts: enabledProducts ?? this.enabledProducts,
    enabledClassicVariants:
        enabledClassicVariants ?? this.enabledClassicVariants,
    warning: warning ?? this.warning,
  );
  void validateAvailability() {
    if (templates.map((t) => t.id).toSet().length != templates.length) {
      throw const FrameCatalogException('Frame IDs must be unique.');
    }
    if (!enabledProducts.any(isProductUsable)) {
      throw const FrameCatalogException(
        'Keep at least one usable product enabled.',
      );
    }
    for (final product in enabledProducts) {
      if (!isProductUsable(product)) {
        throw FrameCatalogException(
          'Keep a compatible frame enabled for ${product.name}, or disable that product first.',
        );
      }
    }
    if (enabledProducts.contains(KioskProduct.classic)) {
      for (final variant in enabledClassicVariants) {
        if (!isModeUsable(modeForVariant(variant))) {
          throw FrameCatalogException(
            'Keep a frame enabled for Classic ${variant.name}, or disable that variant first.',
          );
        }
      }
    }
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'enabledProducts': enabledProducts.map((v) => v.name).toList(),
    'enabledClassicVariants': enabledClassicVariants
        .map((v) => v.name)
        .toList(),
    'templates': templates.map((t) => t.toJson()).toList(),
  };
  factory FrameCatalog.fromJson(Object? value) {
    final map = jsonMap(value);
    if (jsonInt(map, 'schemaVersion') != 1) {
      throw const FrameCatalogException(
        'This catalog was saved by a newer application. Its data has been preserved.',
      );
    }
    final catalog = FrameCatalog(
      templates: jsonList(
        map['templates'],
      ).map(FrameTemplate.fromJson).toList(),
      enabledProducts: jsonList(
        map['enabledProducts'],
      ).map((v) => KioskProduct.values.byName(v as String)).toSet(),
      enabledClassicVariants: jsonList(
        map['enabledClassicVariants'],
      ).map((v) => ClassicVariant.values.byName(v as String)).toSet(),
    );
    catalog.validateAvailability();
    return catalog;
  }
}

KioskProduct productForMode(KioskMode mode) => switch (mode) {
  KioskMode.keychain => KioskProduct.keychain,
  KioskMode.flipbook => KioskProduct.flipbook,
  _ => KioskProduct.classic,
};
ClassicVariant? variantForMode(KioskMode mode) => switch (mode) {
  KioskMode.classicPortrait => ClassicVariant.portrait,
  KioskMode.classicLandscape => ClassicVariant.landscape,
  KioskMode.classicPhotobox => ClassicVariant.photobox,
  _ => null,
};
KioskMode modeForVariant(ClassicVariant variant) => switch (variant) {
  ClassicVariant.portrait => KioskMode.classicPortrait,
  ClassicVariant.landscape => KioskMode.classicLandscape,
  ClassicVariant.photobox => KioskMode.classicPhotobox,
};
Map<String, Object?> jsonMap(Object? value) => value is Map<String, Object?>
    ? value
    : throw const FormatException('Expected an object.');
List<Object?> jsonList(Object? value) => value is List<Object?>
    ? value
    : throw const FormatException('Expected a list.');
String jsonString(Map<String, Object?> map, String key) => map[key] is String
    ? map[key]! as String
    : throw FormatException('Invalid $key.');
bool jsonBool(Map<String, Object?> map, String key) => map[key] is bool
    ? map[key]! as bool
    : throw FormatException('Invalid $key.');
int jsonInt(Map<String, Object?> map, String key) =>
    map[key] is int ? map[key]! as int : throw FormatException('Invalid $key.');
double jsonDouble(Map<String, Object?> map, String key) => map[key] is num
    ? (map[key]! as num).toDouble()
    : throw FormatException('Invalid $key.');
