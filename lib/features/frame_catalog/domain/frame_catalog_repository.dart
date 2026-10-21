import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'frame_artwork_loader.dart';
import 'frame_catalog_models.dart';

/// One app process owns the catalog. Publish immutable artwork first, then
/// atomically rename a flushed manifest; retain the previous complete manifest.
class FrameCatalogRepository {
  final Directory directory;
  final FrameCatalog seed;
  final Future<void> Function(File source, File destination)? publishManifest;
  bool _readOnly = false;
  bool _preserveCurrent = false;
  bool _loaded = false;
  Uint8List? _expectedManifestBytes;
  FrameCatalogRepository({
    required this.directory,
    required this.seed,
    this.publishManifest,
  });
  File get _manifest => File(p.join(directory.path, 'catalog.json'));
  File get _backup => File(p.join(directory.path, 'catalog.backup.json'));
  Future<FrameCatalog> load() async {
    _readOnly = false;
    _preserveCurrent = false;
    await directory.create(recursive: true);
    FrameArtworkLoader.catalogDirectory = directory;
    if (await _manifest.exists() &&
        await _manifest.length() > 8 * 1024 * 1024) {
      _readOnly = true;
      _loaded = true;
      return seed.copyWith(
        warning:
            'The stored frame catalog exceeds the safe loading limit. Its original data is preserved. Staff must repair or restore the catalog before editing.',
      );
    }
    _expectedManifestBytes = await _manifest.exists()
        ? await _manifest.readAsBytes()
        : null;
    _loaded = true;
    if (!await _manifest.exists() && !await _backup.exists()) return seed;
    String? warning;
    for (final file in [_manifest, _backup]) {
      if (!await file.exists()) continue;
      try {
        if (await file.length() > 8 * 1024 * 1024) {
          throw const FormatException('Catalog is too large.');
        }
        final Object? decoded = jsonDecode(await file.readAsString());
        final map = jsonMap(decoded);
        if (jsonInt(map, 'schemaVersion') != 1) {
          _readOnly = true;
          return seed.copyWith(
            warning:
                'A newer catalog format is stored on this PC. Original files are preserved; update the application before editing frames.',
          );
        }
        final loaded = FrameCatalog.fromJson(decoded);
        for (final template in loaded.templates) {
          await validateArtwork(template.artwork);
        }
        // New shipped definitions are merged by stable ID without changing
        // existing event choices, overrides, or custom templates.
        final ids = loaded.templates.map((t) => t.id).toSet();
        final merged = loaded.copyWith(
          templates: [
            ...loaded.templates,
            ...seed.templates
                .where((t) => !ids.contains(t.id))
                .map((t) => t.copyWith(enabled: false)),
          ],
          warning: warning,
        );
        if (file.path == _backup.path) {
          _preserveCurrent = await _manifest.exists();
          return merged.copyWith(
            warning:
                'The latest frame catalog could not be read. The previous saved catalog was recovered. Original files will be preserved when saving.',
          );
        }
        return merged;
      } catch (_) {
        warning =
            'The stored frame catalog could not be read. Bundled frames are available; original files will be preserved when saving.';
      }
    }
    _preserveCurrent = await _manifest.exists();
    return seed.copyWith(warning: warning);
  }

  Future<void> validateArtwork(FrameArtwork artwork) async {
    if (artwork.isBundled) {
      if (!seed.templates.any(
        (t) => t.artwork.isBundled && t.artwork.path == artwork.path,
      )) {
        throw const FrameCatalogException(
          'Bundled artwork must come from a shipped frame.',
        );
      }
      return;
    }
    final file = FrameArtworkLoader.ownedFile(artwork.path, directory);
    if (!await file.exists() || await file.length() > 30 * 1024 * 1024) {
      throw const FrameCatalogException(
        'The frame artwork is missing or exceeds 30 MB. Import the PNG again.',
      );
    }
    final header = pngDimensions(
      await file
          .openRead(0, 24)
          .fold<BytesBuilder>(
            BytesBuilder(),
            (builder, bytes) => builder..add(bytes),
          )
          .then((builder) => builder.takeBytes()),
    );
    if (header.$1 != artwork.pixelWidth || header.$2 != artwork.pixelHeight) {
      throw const FrameCatalogException(
        'The saved artwork dimensions do not match its PNG.',
      );
    }
  }

  Future<FrameArtwork> importPng(Uint8List bytes, String filename) async {
    if (_readOnly) {
      throw const FrameCatalogException(
        'Update the application before changing this newer catalog.',
      );
    }
    if (bytes.length > 30 * 1024 * 1024) {
      throw const FrameCatalogException('Choose a PNG smaller than 30 MB.');
    }
    final (width, height) = pngDimensions(bytes);
    if (img.decodePng(bytes) == null) {
      throw const FrameCatalogException('The PNG could not be decoded.');
    }
    final relative = 'artwork/${newFrameId()}.png';
    final target = FrameArtworkLoader.ownedFile(relative, directory);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return FrameArtwork(
      path: relative,
      isBundled: false,
      pixelWidth: width,
      pixelHeight: height,
    );
  }

  Future<Uint8List> loadArtwork(FrameArtwork artwork) async {
    await validateArtwork(artwork);
    if (artwork.isBundled) {
      final data = await rootBundle.load(artwork.path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return FrameArtworkLoader.ownedFile(artwork.path, directory).readAsBytes();
  }

  Future<void> save(FrameCatalog catalog) async {
    if (!_loaded) {
      await load();
    }
    if (_readOnly) {
      throw const FrameCatalogException(
        'Update the application before changing this newer catalog. Original data has been preserved.',
      );
    }
    await directory.create(recursive: true);
    final lock = await File(
      p.join(directory.path, 'catalog.lock'),
    ).open(mode: FileMode.append);
    var locked = false;
    try {
      try {
        // Nonblocking: another app instance must finish its write first.
        await lock.lock(FileLock.exclusive);
        locked = true;
      } on FileSystemException {
        throw const FrameCatalogException(
          'Another application instance is saving frames. Wait for it to finish and reopen the catalog.',
        );
      }
      if (await _manifest.exists() &&
          await _manifest.length() > 8 * 1024 * 1024) {
        throw const FrameCatalogException(
          'The stored catalog is too large to update safely. Original data has been preserved.',
        );
      }
      final current = await _manifest.exists()
          ? await _manifest.readAsBytes()
          : null;
      if (!_sameBytes(current, _expectedManifestBytes)) {
        throw const FrameCatalogException(
          'Another application instance changed the catalog. Reload its saved version or restart this application before saving. Your draft has not been published.',
        );
      }
      await _publish(catalog);
      _expectedManifestBytes = await _manifest.readAsBytes();
    } finally {
      if (locked) {
        await lock.unlock();
      }
      await lock.close();
    }
  }

  Future<void> _publish(FrameCatalog catalog) async {
    if (_readOnly) {
      throw const FrameCatalogException(
        'Update the application before changing this newer catalog. Original data has been preserved.',
      );
    }
    catalog.validateAvailability();
    for (final template in catalog.templates) {
      template.validate();
      await validateArtwork(template.artwork);
    }
    await directory.create(recursive: true);
    final temporary = File(
      p.join(directory.path, 'catalog-${newFrameId()}.pending'),
    );
    final encoded = jsonEncode(catalog.toJson());
    if (utf8.encode(encoded).length > 8 * 1024 * 1024) {
      throw const FrameCatalogException(
        'The catalog exceeds the 8 MB metadata limit. The previous catalog is preserved.',
      );
    }
    await temporary.writeAsString(encoded, flush: true);
    try {
      if (_preserveCurrent && await _manifest.exists()) {
        await _manifest.copy(
          p.join(directory.path, 'catalog-recovered-${newFrameId()}.json'),
        );
      }
      // A failed final rename must leave the previous manifest and artwork
      // recoverable. Copy rather than moving the current manifest first.
      if (await _manifest.exists() && !_preserveCurrent) {
        await _manifest.copy(_backup.path);
      }
      if (publishManifest != null) {
        await publishManifest!(temporary, _manifest);
      } else {
        await temporary.rename(_manifest.path);
      }
      _preserveCurrent = false;
    } catch (error) {
      if (!await _manifest.exists() && await _backup.exists()) {
        await _backup.copy(_manifest.path);
      }
      throw FrameCatalogException(
        'Frames were not saved. The previous catalog is preserved. $error',
      );
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}

bool _sameBytes(Uint8List? left, Uint8List? right) {
  if (left == null || right == null) {
    return left == null && right == null;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

(int, int) pngDimensions(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 24 ||
      List.generate(8, (i) => bytes[i]).join(',') != signature.join(',') ||
      String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
    throw const FrameCatalogException('Choose a valid PNG artwork file.');
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16), height = data.getUint32(20);
  if (width < 1 ||
      height < 1 ||
      width > 8192 ||
      height > 8192 ||
      width * height > 32000000) {
    throw const FrameCatalogException(
      'PNG dimensions must be at most 8192 pixels per side and 32 million pixels total.',
    );
  }
  return (width, height);
}

Future<FrameCatalog> bundledFrameCatalog() async {
  final templates = <FrameTemplate>[];
  final activeIds = FrameConstants.bundledFrames.map((f) => f.id).toSet();
  final artwork = <String, FrameArtwork>{};
  Future<FrameArtwork> bundledArtwork(String path) async {
    if (artwork.containsKey(path)) {
      return artwork[path]!;
    }
    final data = await rootBundle.load(path);
    final size = pngDimensions(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return artwork[path] = FrameArtwork(
      path: path,
      isBundled: true,
      pixelWidth: size.$1,
      pixelHeight: size.$2,
    );
  }

  for (final definition in FrameConstants.allBundledFrames) {
    final layout = definition.layouts.values.first;
    final kind = switch (layout.type) {
      FrameLayoutType.twoPhotos => FrameTemplateKind.classicPhotobox,
      FrameLayoutType.fourLandscapePhotos => FrameTemplateKind.classicLandscape,
      _ => FrameTemplateKind.classicPortrait,
    };
    final slots = <FrameSlot>[];
    for (final right in [false, true]) {
      final positions = right
          ? layout.rightColumnPositions
          : layout.leftColumnPositions;
      for (var index = 0; index < positions.length; index++) {
        final slot = positions[index];
        slots.add(
          FrameSlot(
            id: '${right ? 'right' : 'left'}-$index',
            photoIndex:
                slot.photoIndex ??
                (right && layout.type == FrameLayoutType.twoPhotos
                    ? index + 2
                    : index),
            left: slot.left,
            top: slot.top,
            width: slot.width,
            height: slot.height,
            rotationDegrees: slot.rotationDegrees,
          ),
        );
      }
    }
    templates.add(
      FrameTemplate(
        id: definition.id,
        name: definition.name,
        revision: 1,
        kind: kind,
        artwork: await bundledArtwork(layout.frameAssetPath),
        slots: slots,
        enabled: activeIds.contains(definition.id),
        bundled: true,
      ),
    );
  }
  for (final definition in FlipbookFrameConstants.bundledFrames) {
    final layout = definition.layout;
    templates.add(
      FrameTemplate(
        id: 'flipbook-${definition.id}',
        name: definition.name,
        revision: 1,
        kind: FrameTemplateKind.flipbook,
        artwork: await bundledArtwork(layout.frameAssetPath),
        slots: [
          for (var i = 0; i < layout.framePositions.length; i++)
            FrameSlot(
              id: 'sequence-$i',
              photoIndex: 0,
              left: layout.framePositions[i].left,
              top: layout.framePositions[i].top,
              width: layout.framePositions[i].width,
              height: layout.framePositions[i].height,
              rotationDegrees: layout.framePositions[i].rotationDegrees,
            ),
        ],
        enabled: true,
        bundled: true,
      ),
    );
  }
  final catalog = FrameCatalog(
    templates: templates,
    enabledProducts: KioskProduct.values.toSet(),
    enabledClassicVariants: ClassicVariant.values.toSet(),
  );
  for (final template in templates) {
    template.validate();
  }
  catalog.validateAvailability();
  return catalog;
}
