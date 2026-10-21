import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';

/// Native printer raster geometry shared by Classic and Keychain.
/// Frame artwork fills this page from the origin without printer compensation.
class FramePdfGeometry {
  static const int rasterWidth = 1240;
  static const int rasterHeight = 1844;
  static const double dpi = 300;
  static const double pageWidth = rasterWidth / dpi * PdfPageFormat.inch;
  static const double pageHeight = rasterHeight / dpi * PdfPageFormat.inch;
  static const PdfPageFormat pageFormat = PdfPageFormat(pageWidth, pageHeight);
}

/// A frame/photo input for one Keychain variant.
///
/// The layout and frame image are carried per variant. This is important:
/// Keychain does not reuse one frame layout for all four quadrants.
class KeychainCompositionInput {
  final FrameLayout layout;
  final Uint8List frameBytes;
  final List<Uint8List> photoBytes;

  KeychainCompositionInput({
    required this.layout,
    required this.frameBytes,
    required List<Uint8List> photoBytes,
  }) : photoBytes = List.unmodifiable(photoBytes);
}

/// Non-widget compositor used by the Keychain output pipeline.
class FrameCompositionRenderer {
  static const int requiredPhotoCount = 4;
  static const double keychainScale = 0.5;
  static const int keychainVariantWidth = FramePdfGeometry.rasterWidth ~/ 2;
  static const int keychainVariantHeight = FramePdfGeometry.rasterHeight ~/ 2;

  /// Resolves the source photo index for a slot in a frame layout.
  static int photoIndexForSlot(
    FrameLayoutType layoutType, {
    required bool rightColumn,
    required int slotIndex,
  }) {
    if (slotIndex < 0) {
      throw ArgumentError.value(slotIndex, 'slotIndex', 'must be non-negative');
    }

    if (layoutType == FrameLayoutType.twoPhotos && rightColumn) {
      return slotIndex + 2;
    }
    return slotIndex;
  }

  /// Renders one complete composition to a 620×922 PNG, half the native
  /// printer page on each axis, using Classic's untransformed coordinates.
  static Future<Uint8List> renderKeychainVariantPng({
    required KeychainCompositionInput input,
  }) async {
    _validatePhotoBytes(input.photoBytes, fieldName: 'photoBytes');
    final frame = img.decodeImage(input.frameBytes);
    if (frame == null) {
      throw StateError('Unable to decode the Keychain frame image.');
    }
    final photoImages = <img.Image>[];
    for (final bytes in input.photoBytes) {
      final photo = img.decodeImage(bytes);
      if (photo == null) {
        throw StateError('Unable to decode a Keychain photo image.');
      }
      photoImages.add(photo);
    }

    final canvas = renderDecodedVariant(
      layout: input.layout,
      frame: frame,
      photos: photoImages,
    );
    return Uint8List.fromList(img.encodePng(canvas));
  }

  /// Shared exact crop/rotation/alpha compositor for still and motion output.
  static img.Image renderDecodedVariant({
    required FrameLayout layout,
    required img.Image frame,
    required List<img.Image> photos,
    int width = keychainVariantWidth,
    int height = keychainVariantHeight,
    String filterId = 'no_filter',
  }) {
    if (photos.length != requiredPhotoCount) {
      throw ArgumentError('Exactly four decoded photos are required.');
    }
    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    _paintPhotoSlots(canvas, layout, photos, filterId);
    final overlay = img.copyResize(frame, width: width, height: height);
    img.compositeImage(canvas, overlay, dstX: 0, dstY: 0);
    return canvas;
  }

  /// Creates a 1240×1844 PNG sheet in TL, TR, BL, BR order, with no gutters.
  static Uint8List generateKeychainSheetPng({
    required List<Uint8List> variantPngs,
  }) {
    _validateVariantPngs(variantPngs);
    final sheet = img.Image(
      width: FramePdfGeometry.rasterWidth,
      height: FramePdfGeometry.rasterHeight,
    );
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    for (var index = 0; index < variantPngs.length; index++) {
      final decoded = img.decodeImage(variantPngs[index]);
      if (decoded == null) {
        throw StateError('Unable to decode Keychain variant $index.');
      }
      final tile = img.copyResize(
        decoded,
        width: keychainVariantWidth,
        height: keychainVariantHeight,
      );
      img.compositeImage(
        sheet,
        tile,
        dstX: (index % 2) * keychainVariantWidth,
        dstY: (index ~/ 2) * keychainVariantHeight,
      );
    }
    return Uint8List.fromList(img.encodePng(sheet));
  }

  /// Creates the printable native-size PDF from four 620×922 variant PNGs.
  ///
  /// The four tiles fill the page and touch at their edges, with no offsets.
  static Future<Uint8List> generateKeychainSheetPdf({
    required List<Uint8List> variantPngs,
  }) async {
    _validateVariantPngs(variantPngs);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: FramePdfGeometry.pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          final tileWidth = FramePdfGeometry.pageWidth * keychainScale;
          final tileHeight = FramePdfGeometry.pageHeight * keychainScale;
          final sheet = pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
              for (var index = 0; index < variantPngs.length; index++)
                pw.Positioned(
                  left: (index % 2) * tileWidth,
                  top: (index ~/ 2) * tileHeight,
                  child: pw.SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: pw.Image(
                      pw.MemoryImage(variantPngs[index]),
                      fit: pw.BoxFit.fill,
                    ),
                  ),
                ),
            ],
          );
          return sheet;
        },
      ),
    );
    return pdf.save();
  }

  static void _paintPhotoSlots(
    img.Image canvas,
    FrameLayout layout,
    List<img.Image> photos,
    String filterId,
  ) {
    final horizontalScale = canvas.width / FramePdfGeometry.pageWidth;
    final verticalScale = canvas.height / FramePdfGeometry.pageHeight;
    if ((horizontalScale - verticalScale).abs() > 0.0001) {
      throw StateError(
        'Keychain output must preserve the native Classic page ratio.',
      );
    }
    final scale = horizontalScale;
    final positions = <({FramePhotoPosition position, int photoIndex})>[];
    for (var index = 0; index < layout.leftColumnPositions.length; index++) {
      positions.add((
        position: layout.leftColumnPositions[index],
        photoIndex:
            layout.leftColumnPositions[index].photoIndex ??
            photoIndexForSlot(
              layout.type,
              rightColumn: false,
              slotIndex: index,
            ),
      ));
    }
    for (var index = 0; index < layout.rightColumnPositions.length; index++) {
      positions.add((
        position: layout.rightColumnPositions[index],
        photoIndex:
            layout.rightColumnPositions[index].photoIndex ??
            photoIndexForSlot(layout.type, rightColumn: true, slotIndex: index),
      ));
    }

    for (final slot in positions) {
      final position = slot.position;
      final scaledLeft = (position.left * scale).round();
      final scaledTop = (position.top * scale).round();
      final scaledRight = ((position.left + position.width) * scale).round();
      final scaledBottom = ((position.top + position.height) * scale).round();
      if (position.rotationDegrees != 0) {
        final fullWidth = math.max(1, scaledRight - scaledLeft);
        final fullHeight = math.max(1, scaledBottom - scaledTop);
        // Match Classic PDF/editor: fit the full unrotated rectangle, rotate
        // about its center, and clip only at the page boundary. Transparent
        // expanded corners must not erase neighbouring photo slots.
        final fitted = _fitPhoto(
          photos[slot.photoIndex],
          fullWidth,
          fullHeight,
          filterId,
        ).convert(numChannels: 4);
        final rotated = img.copyRotate(
          fitted,
          angle: -position.rotationDegrees,
        );
        _compositeClipped(
          canvas,
          rotated,
          scaledLeft + ((fullWidth - rotated.width) / 2).round(),
          scaledTop + ((fullHeight - rotated.height) / 2).round(),
        );
        continue;
      }
      // Cover the entire authored slot before page clipping. Refitting to its
      // visible fragment would change the source crop at a negative/page edge.
      final width = math.max(1, scaledRight - scaledLeft);
      final height = math.max(1, scaledBottom - scaledTop);
      final photo = _fitPhoto(photos[slot.photoIndex], width, height, filterId);
      _compositeClipped(canvas, photo, scaledLeft, scaledTop);
    }
  }

  static void _compositeClipped(
    img.Image canvas,
    img.Image photo,
    int left,
    int top,
  ) {
    final dstX = math.max(0, left), dstY = math.max(0, top);
    final srcX = math.max(0, -left), srcY = math.max(0, -top);
    final width = math.min(canvas.width - dstX, photo.width - srcX);
    final height = math.min(canvas.height - dstY, photo.height - srcY);
    if (width <= 0 || height <= 0) {
      return;
    }
    img.compositeImage(
      canvas,
      photo,
      dstX: dstX,
      dstY: dstY,
      dstW: width,
      dstH: height,
      srcX: srcX,
      srcY: srcY,
      srcW: width,
      srcH: height,
    );
  }

  static img.Image _fitPhoto(
    img.Image source,
    int width,
    int height, [
    String filterId = 'no_filter',
  ]) {
    if (filterId != 'no_filter' &&
        (source.format != img.Format.uint8 ||
            source.numFrames != 1 ||
            source.hasPalette ||
            (source.exif.imageIfd.hasOrientation &&
                source.exif.imageIfd.orientation != 1))) {
      return _fitPhoto(
        _filterWhole(img.Image.from(source), filterId),
        width,
        height,
      );
    }
    final targetAspect = width / height;
    final sourceAspect = source.width / source.height;
    var cropWidth = source.width;
    var cropHeight = source.height;
    var cropX = 0;
    var cropY = 0;
    if (sourceAspect > targetAspect) {
      cropWidth = (source.height * targetAspect).round();
      cropX = (source.width - cropWidth) ~/ 2;
    } else if (sourceAspect < targetAspect) {
      cropHeight = (source.width / targetAspect).round();
      cropY = (source.height - cropHeight) ~/ 2;
    }
    // Same nearest-neighbour sample coordinates as copyCrop + copyResize,
    // without allocating/copying a multi-megapixel crop for every slot.
    if (source.format == img.Format.uint8 &&
        source.numFrames == 1 &&
        !source.hasPalette &&
        (!source.exif.imageIfd.hasOrientation ||
            source.exif.imageIfd.orientation == 1)) {
      final result = img.Image(
        width: width,
        height: height,
        numChannels: source.numChannels,
      );
      final pixel = source.getPixel(0, 0);
      final dx = cropWidth / width;
      final dy = cropHeight / height;
      for (var y = 0; y < height; y++) {
        final sy = cropY + (y * dy).toInt();
        for (var x = 0; x < width; x++) {
          source.getPixel(cropX + (x * dx).toInt(), sy, pixel);
          result.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, pixel.a);
        }
      }
      if (filterId == 'photobooth')
        return FilterConstants.applyPhotoboothFilter(
          result,
          sourceWidth: source.width,
          sourceHeight: source.height,
          cropX: cropX,
          cropY: cropY,
          scaleX: dx,
          scaleY: dy,
        );
      return _filterWhole(result, filterId);
    }
    final cropped = img.copyCrop(
      source,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
    return img.copyResize(cropped, width: width, height: height);
  }

  static void _validatePhotoBytes(
    List<Uint8List> photoBytes, {
    required String fieldName,
  }) {
    if (photoBytes.length != requiredPhotoCount) {
      throw ArgumentError.value(
        photoBytes.length,
        fieldName,
        'must contain exactly $requiredPhotoCount images',
      );
    }
    for (var index = 0; index < photoBytes.length; index++) {
      if (photoBytes[index].isEmpty) {
        throw ArgumentError.value(
          index,
          fieldName,
          'contains an empty image at index $index',
        );
      }
    }
  }

  static void _validateVariantPngs(List<Uint8List> variantPngs) {
    if (variantPngs.length != requiredPhotoCount) {
      throw ArgumentError.value(
        variantPngs.length,
        'variantPngs',
        'must contain exactly $requiredPhotoCount variants',
      );
    }
    for (var index = 0; index < variantPngs.length; index++) {
      if (variantPngs[index].isEmpty) {
        throw ArgumentError.value(
          index,
          'variantPngs',
          'contains an empty PNG at index $index',
        );
      }
    }
  }
}

img.Image _filterWhole(img.Image s, String id) => switch (id) {
  'no_filter' => s,
  'photobooth' => FilterConstants.applyPhotoboothFilter(s),
  'vintage_sepia' => FilterConstants.applyVintageFilter(s),
  'hdr_boost' => FilterConstants.applyHdrFilter(s),
  'mono_b1' => FilterConstants.applyMonoFilter(s),
  _ => throw StateError(id),
};
