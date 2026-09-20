import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_composition_renderer.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';

typedef FrameAssetLoader = Future<ByteData> Function(String assetPath);

const int _previewPhotoMaxDimension = 640;
const int _previewFrameWidth = 600;
const int _previewFrameHeight = 900;
const int _previewJpegQuality = 82;

/// Returned to callers whose preview request was replaced by a newer request.
///
/// The design screen treats this as an expected result of rapid picker changes.
/// Keeping the cancellation explicit prevents a replaced request from holding
/// a completer or an isolate job in an unbounded queue.
class KeychainPreviewCancelledException implements Exception {
  const KeychainPreviewCancelledException();

  @override
  String toString() => 'Keychain preview request was superseded.';
}

class _PreviewRequest {
  final String key;
  final KeychainVariantSelection selection;
  final List<PhotoModel> photos;
  final Completer<Uint8List> completer = Completer<Uint8List>();

  _PreviewRequest({
    required this.key,
    required this.selection,
    required this.photos,
  });
}

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
  final Map<String, Uint8List> _frameBytesById = <String, Uint8List>{};
  final Map<String, Uint8List> _previewFrameBytesById = <String, Uint8List>{};
  final Map<String, List<Uint8List>> _previewPhotosByFilter =
      <String, List<Uint8List>>{};
  final Map<String, Uint8List> _previewPngBySelection = <String, Uint8List>{};

  String? _activePhotoSetKey;
  Future<List<Uint8List>>? _originalsFuture;
  Future<List<Uint8List>>? _previewSourcesFuture;

  Future<Uint8List>? _previewInFlight;
  String? _previewInFlightKey;
  _PreviewRequest? _queuedPreview;
  bool _disposed = false;

  KeychainCompositionService({FrameAssetLoader? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.load;

  /// Releases cached preview data and cancels a request that has not started.
  ///
  /// An isolate already doing CPU work is allowed to finish; its result is
  /// discarded after disposal. This keeps isolate teardown out of the UI path
  /// and avoids touching a disposed widget from a late completion.
  void dispose() {
    _disposed = true;
    final queued = _queuedPreview;
    _queuedPreview = null;
    if (queued != null && !queued.completer.isCompleted) {
      queued.completer.completeError(
        const KeychainPreviewCancelledException(),
        StackTrace.current,
      );
    }
    _previewPngBySelection.clear();
    _previewPhotosByFilter.clear();
    _previewFrameBytesById.clear();
    _frameBytesById.clear();
    _originalsFuture = null;
    _previewSourcesFuture = null;
    _activePhotoSetKey = null;
  }

  Future<KeychainRenderOutput> render({
    required KeychainSessionState session,
    required List<PhotoModel> photos,
  }) async {
    if (session.variants.length != keychainVariantCount) {
      throw StateError('Keychain sessions require exactly four variants.');
    }

    final originals = await _getOriginals(photos);
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

  /// Renders one selected design for the live design preview.
  ///
  /// This method is retained as the design screen's public preview API. It
  /// delegates to the bounded preview pipeline so existing callers do not
  /// accidentally bring the full-resolution originals back into the UI
  /// isolate.
  Future<Uint8List> renderVariant({
    required KeychainVariantSelection selection,
    required List<PhotoModel> photos,
  }) => renderVariantPreview(selection: selection, photos: photos);

  /// Renders one selected design from bounded photo/frame sources.
  ///
  /// File and Flutter asset reads happen before the data is sent to an
  /// isolate. Downscaling, filtering, and composition are all isolate work.
  /// At most one request runs and one newer request waits behind it; every
  /// older queued request is completed with [KeychainPreviewCancelledException].
  Future<Uint8List> renderVariantPreview({
    required KeychainVariantSelection selection,
    required List<PhotoModel> photos,
  }) {
    if (_disposed) {
      return Future<Uint8List>.error(
        StateError('Keychain composition service has been disposed.'),
      );
    }

    final photoSetKey = _photoSetKey(photos);
    _preparePhotoSetCache(photoSetKey, photos);
    final key = '$photoSetKey:${selection.frameId}:${selection.filterId}';
    final cached = _previewPngBySelection[key];
    if (cached != null) {
      return Future<Uint8List>.value(Uint8List.fromList(cached));
    }

    if (_previewInFlightKey == key && _previewInFlight != null) {
      return _previewInFlight!;
    }
    final pending = _queuedPreview;
    if (pending?.key == key) {
      return pending!.completer.future;
    }

    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(
        const KeychainPreviewCancelledException(),
        StackTrace.current,
      );
    }
    final request = _PreviewRequest(
      key: key,
      selection: selection,
      photos: List<PhotoModel>.from(photos),
    );
    if (_previewInFlight != null) {
      _queuedPreview = request;
    } else {
      _startPreview(request);
    }
    return request.completer.future;
  }

  void _preparePhotoSetCache(String photoSetKey, List<PhotoModel> photos) {
    if (_activePhotoSetKey == photoSetKey) return;

    _activePhotoSetKey = photoSetKey;
    _originalsFuture = _readOriginalsFromDisk(List<PhotoModel>.from(photos));
    _previewSourcesFuture = null;
    _previewPhotosByFilter.clear();
    _previewPngBySelection.clear();
  }

  Future<void> _completePreview(
    _PreviewRequest request,
    Future<Uint8List> previewFuture,
  ) async {
    try {
      final png = await previewFuture;
      if (!_disposed) {
        _previewPngBySelection[request.key] = Uint8List.fromList(png);
      }
      if (!request.completer.isCompleted) {
        request.completer.complete(Uint8List.fromList(png));
      }
    } catch (error, stackTrace) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(error, stackTrace);
      }
    } finally {
      if (identical(_previewInFlight, previewFuture)) {
        _previewInFlight = null;
        _previewInFlightKey = null;
        final next = _queuedPreview;
        _queuedPreview = null;
        if (!_disposed && next != null) {
          _startPreview(next);
        }
      }
    }
  }

  void _startPreview(_PreviewRequest request) {
    final previewFuture = _renderPreviewNow(
      selection: request.selection,
      photos: request.photos,
    );
    _previewInFlight = previewFuture;
    _previewInFlightKey = request.key;
    unawaited(_completePreview(request, previewFuture));
  }

  Future<Uint8List> _renderPreviewNow({
    required KeychainVariantSelection selection,
    required List<PhotoModel> photos,
  }) async {
    final photoSetKey = _photoSetKey(photos);
    final originals = await _getOriginals(photos);
    final previewSources = await _getPreviewSources(photoSetKey);
    final filteredPhotos = await _getFilteredPreviewPhotos(
      photoSetKey: photoSetKey,
      filterId: selection.filterId,
      previewSources: previewSources,
    );
    final frame = KeychainFrameCatalog.byId(selection.frameId);
    final previewFrameBytes = await _getPreviewFrameBytes(frame);
    final layout = _layoutFor(frame);

    // [originals] is intentionally awaited above to ensure malformed/missing
    // source files fail before entering the isolate. The bounded sources are
    // the only photo bytes dispatched to CPU-heavy preview work.
    if (originals.length != previewSources.length) {
      throw StateError('Preview source count does not match originals.');
    }
    return Isolate.run<Uint8List>(
      () => _renderPreviewInIsolate(
        layoutType: layout.type.index,
        leftPositions: _positionDto(layout.leftColumnPositions),
        rightPositions: _positionDto(layout.rightColumnPositions),
        topOffset: layout.topOffset,
        frameAssetPath: layout.frameAssetPath,
        frameBytes: previewFrameBytes,
        photoBytes: filteredPhotos,
      ),
    );
  }

  Future<List<Uint8List>> _getPreviewSources(String photoSetKey) async {
    if (_activePhotoSetKey != photoSetKey) {
      throw const KeychainPreviewCancelledException();
    }
    final sourcesFuture = _previewSourcesFuture;
    if (sourcesFuture != null) return sourcesFuture;

    final originalsFuture = _originalsFuture;
    if (originalsFuture == null) {
      throw StateError('Preview photo cache was not initialized.');
    }
    final future = _buildPreviewSources(originalsFuture);
    _previewSourcesFuture = future;
    final sources = await future;
    if (_activePhotoSetKey != photoSetKey) {
      throw const KeychainPreviewCancelledException();
    }
    return sources;
  }

  Future<List<Uint8List>> _buildPreviewSources(
    Future<List<Uint8List>> originalsFuture,
  ) async {
    final originals = await originalsFuture;
    return Isolate.run<List<Uint8List>>(
      () => _downscalePreviewPhotosInIsolate(originals),
    );
  }

  Future<List<Uint8List>> _getFilteredPreviewPhotos({
    required String photoSetKey,
    required String filterId,
    required List<Uint8List> previewSources,
  }) async {
    if (_activePhotoSetKey != photoSetKey) {
      throw const KeychainPreviewCancelledException();
    }
    final cacheKey = '$photoSetKey:$filterId';
    final cached = _previewPhotosByFilter[cacheKey];
    if (cached != null) return cached;

    final filtered = await Isolate.run<List<Uint8List>>(
      () => _applyPreviewFilterInIsolate(previewSources, filterId),
    );
    if (_activePhotoSetKey != photoSetKey) {
      throw const KeychainPreviewCancelledException();
    }
    _previewPhotosByFilter[cacheKey] = filtered;
    return filtered;
  }

  Future<Uint8List> _getPreviewFrameBytes(FrameDefinition frame) async {
    final cached = _previewFrameBytesById[frame.id];
    if (cached != null) return cached;

    final frameBytes = await _getFrameBytes(frame);
    final previewFrame = await Isolate.run<Uint8List>(
      () => _downscalePreviewFrameInIsolate(frameBytes),
    );
    _previewFrameBytesById[frame.id] = previewFrame;
    return previewFrame;
  }

  Future<Uint8List> _renderSelection({
    required KeychainVariantSelection selection,
    required List<Uint8List> photoBytes,
  }) async {
    final frame = KeychainFrameCatalog.byId(selection.frameId);
    final layout = _layoutFor(frame);
    final frameBytes = await _getFrameBytes(frame);
    final input = KeychainCompositionInput(
      layout: layout,
      frameBytes: frameBytes,
      photoBytes: photoBytes,
    );
    return FrameCompositionRenderer.renderKeychainVariantPng(input: input);
  }

  Future<Uint8List> _getFrameBytes(FrameDefinition frame) async {
    final cached = _frameBytesById[frame.id];
    if (cached != null) return cached;
    final layout = _layoutFor(frame);
    final frameData = await _loadAsset(layout.frameAssetPath);
    final bytes = Uint8List.fromList(
      frameData.buffer.asUint8List(
        frameData.offsetInBytes,
        frameData.lengthInBytes,
      ),
    );
    _frameBytesById[frame.id] = bytes;
    return bytes;
  }

  Future<List<Uint8List>> _getOriginals(List<PhotoModel> photos) {
    final photoSetKey = _photoSetKey(photos);
    _preparePhotoSetCache(photoSetKey, photos);
    final originalsFuture = _originalsFuture;
    if (originalsFuture == null) {
      throw StateError('Original photo cache was not initialized.');
    }
    return originalsFuture;
  }

  String _photoSetKey(List<PhotoModel> photos) {
    final sortedPhotos = List<PhotoModel>.from(photos)
      ..sort((left, right) => left.index.compareTo(right.index));
    return sortedPhotos
        .map((photo) => '${photo.index}:${photo.imagePath}')
        .join('|');
  }

  Future<List<Uint8List>> _readOriginalsFromDisk(
    List<PhotoModel> photos,
  ) async {
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

List<List<double>> _positionDto(List<FramePhotoPosition> positions) {
  return [
    for (final position in positions)
      <double>[
        position.left,
        position.top,
        position.width,
        position.height,
        position.rotationDegrees,
      ],
  ];
}

List<Uint8List> _downscalePreviewPhotosInIsolate(List<Uint8List> originals) {
  return [
    for (final original in originals)
      _encodePreviewPhoto(_decodeRequiredImage(original)),
  ];
}

Uint8List _downscalePreviewFrameInIsolate(Uint8List frameBytes) {
  final frame = _decodeRequiredImage(frameBytes);
  final resized = img.copyResize(
    frame,
    width: _previewFrameWidth,
    height: _previewFrameHeight,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodePng(resized));
}

List<Uint8List> _applyPreviewFilterInIsolate(
  List<Uint8List> previewSources,
  String filterId,
) {
  return [
    for (final source in previewSources)
      _encodeFilteredPreviewPhoto(source, filterId),
  ];
}

Uint8List _encodeFilteredPreviewPhoto(Uint8List source, String filterId) {
  final decoded = _decodeRequiredImage(source);
  final filtered = _applyFilterById(decoded, filterId);
  return Uint8List.fromList(
    img.encodeJpg(filtered, quality: _previewJpegQuality),
  );
}

img.Image _decodeRequiredImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Unable to decode a Keychain preview image.');
  }
  return decoded;
}

Uint8List _encodePreviewPhoto(img.Image source) {
  final longestSide = math.max(source.width, source.height);
  final scale = math.min(1.0, _previewPhotoMaxDimension / longestSide);
  final resized = scale < 1.0
      ? img.copyResize(
          source,
          width: math.max(1, (source.width * scale).round()),
          height: math.max(1, (source.height * scale).round()),
          interpolation: img.Interpolation.average,
        )
      : source;
  return Uint8List.fromList(
    img.encodeJpg(resized, quality: _previewJpegQuality),
  );
}

img.Image _applyFilterById(img.Image image, String filterId) {
  switch (filterId) {
    case 'no_filter':
      return image;
    case 'vintage_sepia':
      return FilterConstants.applyVintageFilter(image);
    case 'hdr_boost':
      return FilterConstants.applyHdrFilter(image);
    case 'mono_b1':
      return FilterConstants.applyMonoFilter(image);
    case 'photobooth':
      return FilterConstants.applyPhotoboothFilter(image);
    default:
      throw ArgumentError.value(
        filterId,
        'filterId',
        'is not a supported Keychain preview filter',
      );
  }
}

Future<Uint8List> _renderPreviewInIsolate({
  required int layoutType,
  required List<List<double>> leftPositions,
  required List<List<double>> rightPositions,
  required double topOffset,
  required String frameAssetPath,
  required Uint8List frameBytes,
  required List<Uint8List> photoBytes,
}) {
  final layout = FrameLayout(
    type: FrameLayoutType.values[layoutType],
    leftColumnPositions: _positionsFromDto(leftPositions),
    rightColumnPositions: _positionsFromDto(rightPositions),
    topOffset: topOffset,
    frameAssetPath: frameAssetPath,
  );
  return FrameCompositionRenderer.renderKeychainVariantPng(
    input: KeychainCompositionInput(
      layout: layout,
      frameBytes: frameBytes,
      photoBytes: photoBytes,
    ),
  );
}

List<FramePhotoPosition> _positionsFromDto(List<List<double>> positions) {
  return [
    for (final position in positions)
      FramePhotoPosition(
        left: position[0],
        top: position[1],
        width: position[2],
        height: position[3],
        rotationDegrees: position[4],
      ),
  ];
}
