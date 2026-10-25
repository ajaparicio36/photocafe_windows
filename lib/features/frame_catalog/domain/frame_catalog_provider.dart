import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'frame_catalog_models.dart';
import 'frame_catalog_repository.dart';
import 'frame_catalog_runtime.dart';

final frameCatalogRepositoryProvider = FutureProvider<FrameCatalogRepository>(
  (ref) async => FrameCatalogRepository(
    directory: Directory(
      p.join((await getApplicationSupportDirectory()).path, 'frame_catalog'),
    ),
    seed: await bundledFrameCatalog(),
  ),
);
final frameCatalogProvider =
    AsyncNotifierProvider<FrameCatalogNotifier, FrameCatalog>(
      FrameCatalogNotifier.new,
    );

class FrameCatalogNotifier extends AsyncNotifier<FrameCatalog> {
  Future<void> _writes = Future.value();
  late FrameCatalogRepository _repository;
  @override
  Future<FrameCatalog> build() async {
    _repository = await ref.watch(frameCatalogRepositoryProvider.future);
    FrameCatalog catalog;
    try {
      catalog = await _repository.load();
    } on FileSystemException {
      catalog = _repository.seed.copyWith(
        warning:
            'Local frame storage is unavailable. Bundled frames are usable; check storage permissions before saving changes.',
      );
    }
    FrameCatalogRuntime.instance.replaceCatalog(catalog);
    return catalog;
  }

  Future<FrameArtwork> importPng(Uint8List bytes, String filename) async =>
      _repository.importPng(bytes, filename);
  Future<Uint8List> loadArtwork(FrameArtwork artwork) =>
      _repository.loadArtwork(artwork);
  Future<FrameCatalog> reload() {
    final result = _writes.then((_) async {
      final catalog = await _repository.load();
      state = AsyncData(catalog);
      FrameCatalogRuntime.instance.replaceCatalog(catalog);
      return catalog;
    });
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _mutate(FrameCatalog Function(FrameCatalog current) update) {
    final result = _writes.then((_) async {
      final current = state.requireValue;
      final next = update(current);
      await _repository.save(next);
      state = AsyncData(next);
      FrameCatalogRuntime.instance.replaceCatalog(next);
    });
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> saveTemplate(FrameTemplate template) => _mutate((catalog) {
    template.validate();
    final existing = catalog.templates
        .where((t) => t.id == template.id)
        .firstOrNull;
    if (existing != null &&
        (existing.revision != template.revision ||
            existing.kind != template.kind)) {
      throw const FrameCatalogException(
        'This frame changed while you were editing. Reopen its latest revision before saving.',
      );
    }
    if (existing == null && template.bundled) {
      throw const FrameCatalogException(
        'A new staff frame cannot replace a bundled seed.',
      );
    }
    final saved = template.copyWith(
      name: template.name.trim(),
      revision: existing == null ? 1 : existing.revision + 1,
      bundled: false,
    );
    return catalog.copyWith(
      templates: [
        for (final entry in catalog.templates)
          if (entry.id == template.id) saved else entry,
        if (existing == null) saved,
      ],
    );
  });
  Future<void> setFrameEnabled(String id, bool enabled) => _mutate((catalog) {
    final current = catalog.byId(id);
    return catalog.copyWith(
      templates: [
        for (final entry in catalog.templates)
          if (entry.id == id)
            current.copyWith(enabled: enabled, revision: current.revision + 1)
          else
            entry,
      ],
    );
  });
  Future<void> setProductEnabled(KioskProduct product, bool enabled) => _mutate(
    (catalog) => catalog.copyWith(
      enabledProducts: {...catalog.enabledProducts}..toggle(product, enabled),
    ),
  );
  Future<void> setClassicVariantEnabled(ClassicVariant variant, bool enabled) =>
      _mutate(
        (catalog) => catalog.copyWith(
          enabledClassicVariants: {...catalog.enabledClassicVariants}
            ..toggle(variant, enabled),
        ),
      );
}

extension _Membership<T> on Set<T> {
  void toggle(T value, bool enabled) {
    if (enabled) {
      add(value);
    } else {
      remove(value);
    }
  }
}
