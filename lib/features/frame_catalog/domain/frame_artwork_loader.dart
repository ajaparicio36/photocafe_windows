import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'frame_catalog_models.dart';

/// Legacy renderers carry a string artwork reference. Owned artwork uses an
/// explicit scheme so filesystem reads cannot be confused with bundle keys.
class FrameArtworkLoader {
  static Directory? catalogDirectory;
  static const scheme = 'catalog:';
  static String reference(FrameArtwork artwork) =>
      artwork.isBundled ? artwork.path : '$scheme${artwork.path}';
  static File ownedFile(String relativePath, Directory directory) {
    if (!RegExp(r'^artwork/[a-zA-Z0-9_-]+\.png$').hasMatch(relativePath)) {
      throw const FrameCatalogException(
        'Artwork must be an owned PNG inside the frame catalog.',
      );
    }
    final file = File(p.join(directory.path, p.fromUri(relativePath)));
    if (!p.isWithin(
      p.normalize(p.absolute(directory.path)),
      p.normalize(p.absolute(file.path)),
    )) {
      throw const FrameCatalogException('Artwork path is outside the catalog.');
    }
    return file;
  }

  static Future<ByteData> load(String reference) async {
    if (!reference.startsWith(scheme)) return rootBundle.load(reference);
    final directory = catalogDirectory;
    if (directory == null) {
      throw const FrameCatalogException(
        'The local frame catalog has not loaded.',
      );
    }
    final file = ownedFile(reference.substring(scheme.length), directory);
    if (await file.length() > 30 * 1024 * 1024) {
      throw const FrameCatalogException(
        'The frame artwork exceeds 30 MB. Import a smaller PNG.',
      );
    }
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
