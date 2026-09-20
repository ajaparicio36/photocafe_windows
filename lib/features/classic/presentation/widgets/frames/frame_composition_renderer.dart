import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';

/// Geometry used by the Windows printer and by the Keychain imposed sheet.
///
/// Classic's existing PDF path intentionally keeps its printer compensation
/// and page geometry. Keychain composes the four variants first and applies
/// this compensation once to the outer sheet only.
class FramePdfGeometry {
  static const double bleedMm = 3.0;
  static const double pointsPerMillimetre = 2.834645669;
  static const double bleedPoints = bleedMm * pointsPerMillimetre;
  static const double trimWidth = 4 * PdfPageFormat.inch;
  static const double trimHeight = 6 * PdfPageFormat.inch;
  static const double pageWidth = trimWidth + (bleedPoints * 2);
  static const double pageHeight = trimHeight + (bleedPoints * 3);
  static const double sheetContentLeft = bleedPoints;
  static const double sheetContentTop = bleedPoints;
  static const double sheetContentWidth = trimWidth;
  static const double sheetContentHeight = trimHeight;
  static const double printerScale = 0.94;
  static const double printerOffsetX = bleedPoints * 0.5;
  static const double printerOffsetY = bleedPoints * -0.92;

  static const PdfPageFormat pageFormat = PdfPageFormat(pageWidth, pageHeight);

  /// Applies the physical-printer compensation exactly once to a page.
  static pw.Widget applyPrinterTransform(pw.Widget child) {
    return pw.Transform.scale(
      scale: printerScale,
      child: pw.Transform.translate(
        offset: const PdfPoint(-printerOffsetX, -printerOffsetY),
        child: child,
      ),
    );
  }
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
  static const int keychainVariantWidth = 600;
  static const int keychainVariantHeight = 900;
  static const double classicFrameCoverageScale = 1.005;

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

  /// Renders one complete Keychain composition directly to a 600×900 PNG.
  ///
  /// The output is a 2×3 inch raster at 300 DPI. It uses the same adjusted
  /// 4×6 page coordinate space as Classic, but does not apply printer
  /// compensation; that belongs to the outer sheet PDF only.
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

    final canvas = img.Image(
      width: keychainVariantWidth,
      height: keychainVariantHeight,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    _paintPhotoSlots(canvas, input.layout, photoImages);
    final frameOverlay = _resizeAndCenterCrop(
      frame,
      width: keychainVariantWidth,
      height: keychainVariantHeight,
      coverageScale: classicFrameCoverageScale,
    );
    img.compositeImage(canvas, frameOverlay, dstX: 0, dstY: 0);
    final pngBytes = Uint8List.fromList(img.encodePng(canvas));
    return _ensurePngDimensions(
      pngBytes,
      width: keychainVariantWidth,
      height: keychainVariantHeight,
      expectedName: 'Keychain variant',
    );
  }

  /// Creates a 1200×1800 PNG sheet in TL, TR, BL, BR order, with no gutters.
  static Uint8List generateKeychainSheetPng({
    required List<Uint8List> variantPngs,
  }) {
    _validateVariantPngs(variantPngs);
    final sheet = img.Image(width: 1200, height: 1800);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    for (var index = 0; index < variantPngs.length; index++) {
      final decoded = img.decodeImage(variantPngs[index]);
      if (decoded == null) {
        throw StateError('Unable to decode Keychain variant $index.');
      }
      final tile = img.copyResize(decoded, width: 600, height: 900);
      img.compositeImage(
        sheet,
        tile,
        dstX: (index % 2) * 600,
        dstY: (index ~/ 2) * 900,
      );
    }
    return Uint8List.fromList(img.encodePng(sheet));
  }

  /// Creates the printable 4×6 PDF from four 600×900 variant PNGs.
  ///
  /// The four tiles touch at their edges. Printer compensation is wrapped
  /// around the complete sheet exactly once, never around each quadrant.
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
          return FramePdfGeometry.applyPrinterTransform(sheet);
        },
      ),
    );
    return pdf.save();
  }

  static void _paintPhotoSlots(
    img.Image canvas,
    FrameLayout layout,
    List<img.Image> photos,
  ) {
    final horizontalScale = canvas.width / FramePdfGeometry.pageWidth;
    final verticalScale = canvas.height / FramePdfGeometry.pageHeight;
    if ((horizontalScale - verticalScale).abs() > 0.0001) {
      throw StateError(
        'Keychain output must preserve the adjusted Classic page ratio.',
      );
    }
    final scale = horizontalScale;
    final positions = <({FramePhotoPosition position, int photoIndex})>[];
    for (var index = 0; index < layout.leftColumnPositions.length; index++) {
      positions.add((
        position: layout.leftColumnPositions[index],
        photoIndex: photoIndexForSlot(
          layout.type,
          rightColumn: false,
          slotIndex: index,
        ),
      ));
    }
    for (var index = 0; index < layout.rightColumnPositions.length; index++) {
      positions.add((
        position: layout.rightColumnPositions[index],
        photoIndex: photoIndexForSlot(
          layout.type,
          rightColumn: true,
          slotIndex: index,
        ),
      ));
    }

    for (final slot in positions) {
      final position = slot.position;
      final scaledLeft = (position.left * scale).round();
      final scaledTop = (position.top * scale).round();
      final scaledRight = ((position.left + position.width) * scale).round();
      final scaledBottom = ((position.top + position.height) * scale).round();
      final dstX = math.max(0, math.min(canvas.width - 1, scaledLeft));
      final dstY = math.max(0, math.min(canvas.height - 1, scaledTop));
      final right = math.max(dstX + 1, math.min(canvas.width, scaledRight));
      final bottom = math.max(dstY + 1, math.min(canvas.height, scaledBottom));
      final width = right - dstX;
      final height = bottom - dstY;
      var photo = _fitPhoto(photos[slot.photoIndex], width, height);
      if (position.rotationDegrees != 0) {
        // package:image uses screen coordinates, so its positive rotation
        // direction is opposite the PDF transform used by Classic.
        photo = img.copyRotate(photo, angle: -position.rotationDegrees);
        // Rotation expands the raster bounds. Crop that expansion instead of
        // resizing it, which would make the visible photo smaller than Classic.
        photo = img.copyCrop(
          photo,
          x: (photo.width - width) ~/ 2,
          y: (photo.height - height) ~/ 2,
          width: width,
          height: height,
        );
      }
      img.compositeImage(canvas, photo, dstX: dstX, dstY: dstY);
    }
  }

  static img.Image _resizeAndCenterCrop(
    img.Image source, {
    required int width,
    required int height,
    required double coverageScale,
  }) {
    final coveredWidth = (width * coverageScale).ceil();
    final coveredHeight = (height * coverageScale).ceil();
    final covered = _fitPhoto(source, coveredWidth, coveredHeight);
    return img.copyCrop(
      covered,
      x: (covered.width - width) ~/ 2,
      y: (covered.height - height) ~/ 2,
      width: width,
      height: height,
    );
  }

  static img.Image _fitPhoto(img.Image source, int width, int height) {
    final targetAspect = width / height;
    final sourceAspect = source.width / source.height;
    img.Image cropped;
    if (sourceAspect > targetAspect) {
      final cropWidth = (source.height * targetAspect).round();
      cropped = img.copyCrop(
        source,
        x: (source.width - cropWidth) ~/ 2,
        y: 0,
        width: cropWidth,
        height: source.height,
      );
    } else if (sourceAspect < targetAspect) {
      final cropHeight = (source.width / targetAspect).round();
      cropped = img.copyCrop(
        source,
        x: 0,
        y: (source.height - cropHeight) ~/ 2,
        width: source.width,
        height: cropHeight,
      );
    } else {
      cropped = source;
    }
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

  static Uint8List _ensurePngDimensions(
    Uint8List bytes, {
    required int width,
    required int height,
    required String expectedName,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width != width || decoded.height != height) {
      throw StateError(
        '$expectedName must be $width×$height pixels; got '
        '${decoded == null ? 'an unreadable image' : '${decoded.width}×${decoded.height}'}.',
      );
    }
    return bytes;
  }
}
