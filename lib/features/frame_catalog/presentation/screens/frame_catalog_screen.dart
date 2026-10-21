import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/frame_catalog_models.dart';
import '../../domain/frame_catalog_provider.dart';
import '../widgets/catalog_style.dart';
import 'frame_editor_screen.dart';

class FrameCatalogScreen extends ConsumerStatefulWidget {
  const FrameCatalogScreen({super.key});

  @override
  ConsumerState<FrameCatalogScreen> createState() => _FrameCatalogScreenState();
}

class _FrameCatalogScreenState extends ConsumerState<FrameCatalogScreen> {
  FrameTemplateKind _kind = FrameTemplateKind.classicPortrait;
  String? _busy;
  String? _error;
  String? _success;

  Future<void> _change(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() {
      _busy = key;
      _error = null;
      _success = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = catalogErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _importPng() async {
    if (_busy != null) return;
    setState(() {
      _busy = 'import';
      _error = null;
      _success = null;
    });
    FrameTemplate? template;
    Uint8List? bytes;
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PNG artwork',
            extensions: ['png'],
            mimeTypes: ['image/png'],
          ),
        ],
        confirmButtonText: 'Import PNG',
      );
      if (file == null || !mounted) return;
      bytes = await file.readAsBytes();
      if (!mounted) return;
      final artwork = await ref
          .read(frameCatalogProvider.notifier)
          .importPng(bytes, file.name);
      final name = file.name.replaceFirst(
        RegExp(r'\.png$', caseSensitive: false),
        '',
      );
      template = FrameTemplate.create(
        kind: _kind,
        name: name.length > 100 ? name.substring(0, 100) : name,
        artwork: artwork,
      );
    } catch (error) {
      if (mounted) setState(() => _error = catalogErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    if (template != null && mounted) {
      await _edit(template, isNew: true, artwork: bytes);
    }
  }

  Future<void> _edit(
    FrameTemplate template, {
    bool isNew = false,
    Uint8List? artwork,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FrameEditorScreen(
          template: template,
          isNew: isNew,
          artworkBytes: artwork,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _error = null;
        _success = isNew
            ? 'Frame saved. Enable it when it is ready for customers.'
            : 'Frame saved. New selections will use the updated layout.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(frameCatalogProvider);
    return CatalogTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Frames & modes'),
          actions: [
            IconButton(
              tooltip: 'Reload catalog from disk',
              onPressed: _busy == null && catalog.hasValue
                  ? () => _change('reload', () async {
                      await ref.read(frameCatalogProvider.notifier).reload();
                    })
                  : null,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: FilledButton.icon(
                key: const ValueKey('import-frame'),
                onPressed: _busy == null && catalog.hasValue
                    ? _importPng
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: catalogInk,
                ),
                icon: Icon(
                  _busy == 'import'
                      ? Icons.hourglass_top
                      : Icons.add_photo_alternate_outlined,
                ),
                label: Text(_busy == 'import' ? 'Importing…' : 'Import PNG'),
              ),
            ),
          ],
        ),
        body: catalog.when(
          loading: () => const Center(child: Text('Loading frame catalog…')),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_off_outlined, size: 42),
                  const SizedBox(height: 16),
                  const Text('The frame catalog could not be opened.'),
                  const SizedBox(height: 8),
                  Text(catalogErrorMessage(error), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(frameCatalogProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
          data: _buildCatalog,
        ),
      ),
    );
  }

  Widget _buildCatalog(FrameCatalog catalog) {
    final frames = catalog.templates
        .where((frame) => frame.kind == _kind)
        .toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (catalog.warning != null) ...[
            CatalogNotice(message: catalog.warning!),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            CatalogNotice(
              key: const ValueKey('catalog-error'),
              message: _error!,
              isError: true,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
          ],
          if (_success != null) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: catalogInk),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_success!)),
                  IconButton(
                    tooltip: 'Dismiss message',
                    onPressed: () => setState(() => _success = null),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 280, child: _buildAvailability(catalog)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<FrameTemplateKind>(
                              key: const ValueKey('frame-kind-filter'),
                              initialValue: _kind,
                              decoration: const InputDecoration(
                                labelText: 'Frame collection',
                              ),
                              items: [
                                for (final kind in FrameTemplateKind.values)
                                  DropdownMenuItem(
                                    value: kind,
                                    child: Text(frameKindLabel(kind)),
                                  ),
                              ],
                              onChanged: _busy != null
                                  ? null
                                  : (kind) {
                                      if (kind != null) {
                                        setState(() {
                                          _kind = kind;
                                          _success = null;
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${frames.where((frame) => frame.enabled).length}'
                            ' of ${frames.length} enabled',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _kind == FrameTemplateKind.classicPortrait
                            ? 'Shared by Classic Portrait and Keychain. '
                                  'Import PNG adds a frame to this collection.'
                            : 'Import PNG adds a frame to this collection. '
                                  'New frames stay hidden until enabled.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF51494A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: frames.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library_outlined,
                                      size: 42,
                                      color: catalogInk,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('No frames in this collection'),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Import a PNG, place its photo slots, '
                                      'then save and enable it.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: _busy == null
                                          ? _importPng
                                          : null,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Import PNG'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                key: const ValueKey('staff-frame-list'),
                                itemCount: frames.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildFrameRow(frames[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(FrameCatalog catalog) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Customer menu',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose what customers can start. Keep at least one usable '
            'product enabled.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final product in KioskProduct.values) ...[
            SwitchListTile(
              key: ValueKey('product-${product.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(switch (product) {
                KioskProduct.classic => 'Classic',
                KioskProduct.keychain => 'Keychain',
                KioskProduct.flipbook => 'Flipbook',
              }, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                catalog.isProductUsable(product)
                    ? 'Available to customers'
                    : 'Hidden from customers',
                style: const TextStyle(fontSize: 12),
              ),
              value: catalog.enabledProducts.contains(product),
              onChanged: _busy != null
                  ? null
                  : (enabled) => _change(
                      'product-${product.name}',
                      () => ref
                          .read(frameCatalogProvider.notifier)
                          .setProductEnabled(product, enabled),
                    ),
            ),
            if (product == KioskProduct.classic)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Column(
                  children: [
                    for (final variant in ClassicVariant.values)
                      CheckboxListTile(
                        key: ValueKey('variant-${variant.name}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(switch (variant) {
                          ClassicVariant.portrait => 'Portrait',
                          ClassicVariant.landscape => 'Landscape',
                          ClassicVariant.photobox => 'Photobox',
                        }, style: const TextStyle(fontSize: 14)),
                        value: catalog.enabledClassicVariants.contains(variant),
                        onChanged:
                            _busy != null ||
                                !catalog.enabledProducts.contains(
                                  KioskProduct.classic,
                                )
                            ? null
                            : (enabled) => _change(
                                'variant-${variant.name}',
                                () => ref
                                    .read(frameCatalogProvider.notifier)
                                    .setClassicVariantEnabled(
                                      variant,
                                      enabled ?? false,
                                    ),
                              ),
                      ),
                  ],
                ),
              ),
          ],
          const Divider(height: 28),
          const Text(
            'Frame visibility',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hidden frames remain available here for staff to edit. '
            'Customer sessions in progress keep their selected frame.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          if (_busy != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _busy == 'import' ? 'Importing artwork…' : 'Saving change…',
                style: const TextStyle(fontSize: 13, color: catalogInk),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrameRow(FrameTemplate frame) {
    return Container(
      key: ValueKey('staff-frame-${frame.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7CECE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 86,
            child: _ArtworkThumbnail(artwork: frame.artwork),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  frame.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${frame.slots.length} photo '
                  '${frame.slots.length == 1 ? 'slot' : 'slots'} · '
                  '${frame.bundled ? 'Built-in' : 'Custom'} · '
                  'Revision ${frame.revision}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF51494A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            key: ValueKey('edit-frame-${frame.id}'),
            onPressed: _busy != null ? null : () => _edit(frame),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Semantics(
                  label: 'Enable ${frame.name} for customers',
                  child: Switch(
                    key: ValueKey('enable-frame-${frame.id}'),
                    value: frame.enabled,
                    onChanged: _busy != null
                        ? null
                        : (enabled) => _change(
                            frame.id,
                            () => ref
                                .read(frameCatalogProvider.notifier)
                                .setFrameEnabled(frame.id, enabled),
                          ),
                  ),
                ),
                Text(
                  frame.enabled ? 'Enabled' : 'Hidden',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkThumbnail extends ConsumerStatefulWidget {
  final FrameArtwork artwork;

  const _ArtworkThumbnail({required this.artwork});

  @override
  ConsumerState<_ArtworkThumbnail> createState() => _ArtworkThumbnailState();
}

class _ArtworkThumbnailState extends ConsumerState<_ArtworkThumbnail> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ArtworkThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork.path != widget.artwork.path ||
        oldWidget.artwork.isBundled != widget.artwork.isBundled) {
      _load();
    }
  }

  void _load() {
    _bytes = ref
        .read(frameCatalogProvider.notifier)
        .loadArtwork(widget.artwork);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Tooltip(
            message: 'Artwork unavailable',
            child: Icon(Icons.broken_image_outlined, color: catalogInk),
          );
        }
        if (!snapshot.hasData) {
          return const ColoredBox(color: catalogPaper);
        }
        return Image.memory(
          snapshot.requireData,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) =>
              const Icon(Icons.broken_image_outlined, color: catalogInk),
        );
      },
    );
  }
}
