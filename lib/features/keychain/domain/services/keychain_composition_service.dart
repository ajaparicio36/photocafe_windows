import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'dart:io';

typedef FrameAssetLoader = Future<ByteData> Function(String assetPath);

/// Rendered Keychain media, kept in memory until the print/review screen.
class KeychainRenderOutput {
  final List<Uint8List> variantPngs;
  final Uint8List sheetPng;
  final Uint8List sheetPdf;
  final List<KeychainVariantSelection> selections;

  KeychainRenderOutput({
    required List<Uint8List> variantPngs,
    required this.sheetPng,
    required this.sheetPdf,
    required List<KeychainVariantSelection> selections,
  }) : variantPngs = List.unmodifiable(variantPngs),
       selections = List.unmodifiable(selections) {
    if (this.variantPngs.length != keychainVariantCount ||
        this.selections.length != keychainVariantCount) {
      throw ArgumentError('Keychain output requires exactly four variants.');
    }
  }

  /// Persist every uploadable PNG to the session temp directory.
  Future<KeychainMediaBundle> persist(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final variantFiles = <File>[];
    for (var index = 0; index < variantPngs.length; index++) {
      final file = File(
        p.join(directoryPath, 'keychain_variant_${index + 1}.png'),
      );
      await file.writeAsBytes(variantPngs[index], flush: true);
      variantFiles.add(file);
    }

    final sheetFile = File(p.join(directoryPath, 'keychain_sheet.png'));
    await sheetFile.writeAsBytes(sheetPng, flush: true);
    return KeychainMediaBundle(
      variantFiles: variantFiles,
      sheetFile: sheetFile,
    );
  }
}

class KeychainMediaBundle {
  final List<File> variantFiles;
  final File sheetFile;

  KeychainMediaBundle({
    required List<File> variantFiles,
    required this.sheetFile,
  }) : variantFiles = List.unmodifiable(variantFiles) {
    if (this.variantFiles.length != keychainVariantCount) {
      throw ArgumentError('Keychain media requires exactly four variants.');
    }
  }
}

class KeychainPrintArguments {
  final KeychainRenderOutput output;
  final KeychainMediaBundle mediaBundle;

  const KeychainPrintArguments({
    required this.output,
    required this.mediaBundle,
  });
}

/// Composes independently selected Classic frame/filter variants from the
/// same four originals. It never writes over a source photo.
class KeychainCompositionService {
  final FrameAssetLoader _loadAsset;

  KeychainCompositionService({FrameAssetLoader? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.load;

  Future<KeychainRenderOutput> render({
    required KeychainSessionState session,
    required List<PhotoModel> photos,
  }) async {
    if (session.variants.length != keychainVariantCount) {
      throw StateError('Keychain sessions require exactly four variants.');
    }

    final originals = await _readOriginals(photos);
    final filteredById = <String, List<Uint8List>>{};
    final variantPngs = <Uint8List>[];

    for (final selection in session.variants) {
      final filter = KeychainFilterCatalog.byId(selection.filterId);
      final filteredPhotos = filteredById.putIfAbsent(
        filter.id,
        () => _applyFilterToPhotos(originals, filter),
      );
      variantPngs.add(
        await _renderSelection(
          selection: selection,
          photoBytes: filteredPhotos,
        ),
      );
    }

    final sheetPng = FrameCompositionRenderer.generateKeychainSheetPng(
      variantPngs: variantPngs,
    );
    final sheetPdf = await FrameCompositionRenderer.generateKeychainSheetPdf(
      variantPngs: variantPngs,
    );
    return KeychainRenderOutput(
      variantPngs: variantPngs,
      sheetPng: sheetPng,
      sheetPdf: sheetPdf,
      selections: session.variants,
    );
  }

  /// Renders one selected design without mutating the originals or producing
  /// any session files. The design screen uses this for its live preview.
  Future<Uint8List> renderVariant({
    required KeychainVariantSelection selection,
    required List<PhotoModel> photos,
  }) async {
    final originals = await _readOriginals(photos);
    final filter = KeychainFilterCatalog.byId(selection.filterId);
    return _renderSelection(
      selection: selection,
      photoBytes: _applyFilterToPhotos(originals, filter),
    );
  }

  Future<Uint8List> _renderSelection({
    required KeychainVariantSelection selection,
    required List<Uint8List> photoBytes,
  }) async {
    final frame = KeychainFrameCatalog.byId(selection.frameId);
    final layout = _layoutFor(frame);
    final frameData = await _loadAsset(layout.frameAssetPath);
    final input = KeychainCompositionInput(
      layout: layout,
      frameBytes: frameData.buffer.asUint8List(
        frameData.offsetInBytes,
        frameData.lengthInBytes,
      ),
      photoBytes: photoBytes,
    );
    return FrameCompositionRenderer.renderKeychainVariantPng(input: input);
  }

  Future<List<Uint8List>> _readOriginals(List<PhotoModel> photos) async {
    if (photos.length != keychainVariantCount) {
      throw StateError(
        'Keychain requires exactly $keychainVariantCount original photos.',
      );
    }
    final photosByIndex = <int, PhotoModel>{};
    for (final photo in photos) {
      if (photosByIndex.containsKey(photo.index)) {
        throw StateError('Duplicate original photo index ${photo.index}.');
      }
      photosByIndex[photo.index] = photo;
    }

    final originals = <Uint8List>[];
    for (var index = 0; index < keychainVariantCount; index++) {
      final photo = photosByIndex[index];
      if (photo == null) {
        throw StateError('Keychain requires original photo index $index.');
      }
      final file = File(photo.imagePath);
      if (!await file.exists()) {
        throw StateError('Original photo file not found: ${photo.imagePath}');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('Original photo file is empty: ${photo.imagePath}');
      }
      originals.add(Uint8List.fromList(bytes));
    }
    return originals;
  }

  List<Uint8List> _applyFilterToPhotos(
    List<Uint8List> originals,
    FilterDefinition filter,
  ) {
    return [
      for (final original in originals) _applyFilterToBytes(original, filter),
    ];
  }

  Uint8List _applyFilterToBytes(Uint8List original, FilterDefinition filter) {
    if (filter.id == 'no_filter') {
      return Uint8List.fromList(original);
    }
    final decoded = img.decodeImage(original);
    if (decoded == null) {
      throw StateError('Unable to decode an original photo for filtering.');
    }
    final filtered = filter.applyFilter(img.Image.from(decoded));
    return Uint8List.fromList(img.encodeJpg(filtered, quality: 95));
  }

  FrameLayout _layoutFor(FrameDefinition frame) {
    if (frame.layouts.isEmpty) {
      throw StateError('Frame ${frame.id} does not define a Classic layout.');
    }
    return frame.layouts.values.first;
  }
}
