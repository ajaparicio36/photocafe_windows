import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/frame_catalog_models.dart';
import '../../domain/frame_catalog_provider.dart';
import '../widgets/catalog_style.dart';
import '../widgets/frame_slot_canvas.dart';

class FrameEditorScreen extends ConsumerStatefulWidget {
  final FrameTemplate template;
  final bool isNew;
  final Uint8List? artworkBytes;

  const FrameEditorScreen({
    super.key,
    required this.template,
    this.isNew = false,
    this.artworkBytes,
  });

  @override
  ConsumerState<FrameEditorScreen> createState() => _FrameEditorScreenState();
}

class _FrameEditorScreenState extends ConsumerState<FrameEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late FrameTemplate _draft;
  late TextEditingController _name;
  late Future<Uint8List> _artwork;
  String? _selectedId;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  bool _showArtwork = true;

  FrameSlot? get _selected =>
      _draft.slots.where((slot) => slot.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _draft = widget.template;
    _name = TextEditingController(text: _draft.name);
    _selectedId = _draft.slots.firstOrNull?.id;
    _artwork = widget.artworkBytes != null
        ? Future.value(widget.artworkBytes)
        : ref.read(frameCatalogProvider.notifier).loadArtwork(_draft.artwork);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _changeSlot(FrameSlot slot) {
    setState(() {
      _draft = _draft.copyWith(
        slots: [
          for (final item in _draft.slots) item.id == slot.id ? slot : item,
        ],
      );
      _dirty = true;
    });
  }

  void _addSlot() {
    final slot = FrameSlot(
      id: newFrameId(),
      photoIndex: _draft.kind == FrameTemplateKind.flipbook
          ? 0
          : _draft.slots.length % 4,
      left: _draft.canvasWidth * 0.2,
      top: _draft.canvasHeight * 0.2,
      width: _draft.canvasWidth * 0.35,
      height: _draft.canvasHeight * 0.2,
    );
    setState(() {
      _draft = _draft.copyWith(slots: [..._draft.slots, slot]);
      _selectedId = slot.id;
      _dirty = true;
    });
  }

  void _duplicateSlot() {
    final slot = _selected;
    if (slot == null) return;
    final copy = slot.copyWith(
      id: newFrameId(),
      left: slot.left + 8,
      top: slot.top + 8,
    );
    setState(() {
      _draft = _draft.copyWith(slots: [..._draft.slots, copy]);
      _selectedId = copy.id;
      _dirty = true;
    });
  }

  void _removeSlot() {
    setState(() {
      _draft = _draft.copyWith(
        slots: _draft.slots.where((slot) => slot.id != _selectedId).toList(),
      );
      _selectedId = _draft.slots.firstOrNull?.id;
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => CatalogTheme(
            child: AlertDialog(
              title: const Text('Discard unsaved changes?'),
              content: const Text(
                'Your saved frame will stay as it is. Changes in this editor '
                'will be lost.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep editing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard changes'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _close() async {
    if (_saving || !await _confirmDiscard() || !mounted) return;
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(frameCatalogProvider.notifier)
          .saveTemplate(_draft.copyWith(name: _name.text.trim()));
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = catalogErrorMessage(error);
      });
    }
  }

  Future<void> _reloadSaved() async {
    if (_saving || !await _confirmDiscard() || !mounted) return;
    setState(() => _saving = true);
    try {
      final catalog = await ref.read(frameCatalogProvider.notifier).reload();
      final saved = catalog.byId(_draft.id);
      if (!mounted) return;
      setState(() {
        _draft = saved;
        _name.text = saved.name;
        _selectedId = saved.slots.firstOrNull?.id;
        _dirty = false;
        _error = null;
        _artwork = ref
            .read(frameCatalogProvider.notifier)
            .loadArtwork(saved.artwork);
      });
    } catch (error) {
      if (mounted) setState(() => _error = catalogErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reloadCatalogKeepingDraft() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(frameCatalogProvider.notifier).reload();
    } catch (error) {
      if (mounted) setState(() => _error = catalogErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CatalogTheme(
      child: PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _close();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Back to frame catalog',
              onPressed: _saving ? null : _close,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(widget.isNew ? 'New frame' : 'Edit frame'),
            actions: [
              if (_dirty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Unsaved changes'),
                ),
              TextButton(
                onPressed: _saving ? null : _close,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Cancel'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 20),
                child: FilledButton.icon(
                  key: const ValueKey('save-frame'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: catalogInk,
                  ),
                  icon: Icon(
                    _saving ? Icons.hourglass_top : Icons.save_outlined,
                  ),
                  label: Text(_saving ? 'Saving…' : 'Save frame'),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_error != null) ...[
                    CatalogNotice(message: _error!, isError: true),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _saving
                            ? null
                            : widget.isNew
                            ? _reloadCatalogKeepingDraft
                            : _reloadSaved,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          widget.isNew
                              ? 'Reload catalog and keep draft'
                              : 'Reload saved version',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('frame-name'),
                          controller: _name,
                          enabled: !_saving,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Frame name',
                            counterText: '',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a frame name.'
                              : null,
                          onChanged: (value) => setState(() => _dirty = true),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              frameKindLabel(_draft.kind),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.isNew
                                  ? 'Saved hidden until you enable it'
                                  : 'Revision ${_draft.revision} · '
                                        '${_draft.enabled ? 'Enabled' : 'Hidden'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCanvas()),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: constraints.maxWidth < 1000 ? 276 : 320,
                            child: _buildInspector(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Frame layout',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            FilterChip(
              label: const Text('Show artwork'),
              selected: _showArtwork,
              onSelected: _saving
                  ? null
                  : (value) => setState(() => _showArtwork = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<Uint8List>(
            future: _artwork,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 36),
                      const SizedBox(height: 12),
                      const Text('The frame artwork could not be loaded.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _artwork = ref
                              .read(frameCatalogProvider.notifier)
                              .loadArtwork(_draft.artwork);
                        }),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Loading frame artwork…'));
              }
              return FrameSlotCanvas(
                template: _draft,
                artwork: snapshot.requireData,
                selectedSlotId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
                onSlotChanged: _changeSlot,
                enabled: !_saving,
                showArtwork: _showArtwork,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Drag a slot to move it. Use the square to resize and the round '
          'handle to rotate. Arrow keys nudge; Shift moves 10 points.',
          style: TextStyle(fontSize: 12, color: Color(0xFF51494A)),
        ),
        const SizedBox(height: 6),
        Text(
          '${_draft.canvasWidth} × ${_draft.canvasHeight} pt canvas · '
          '${_draft.artwork.pixelWidth} × ${_draft.artwork.pixelHeight} px PNG',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF51494A),
            fontFamily: 'SpaceMono',
          ),
        ),
      ],
    );
  }

  Widget _buildInspector() {
    final selected = _selected;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Photo slots (${_draft.slots.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('add-slot'),
                tooltip: 'Add photo slot',
                onPressed: _saving || _draft.slots.length >= 32
                    ? null
                    : _addSlot,
                icon: const Icon(Icons.add_box_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('slot-selector-${_selectedId ?? 'none'}'),
            initialValue: _selectedId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Selected slot'),
            hint: const Text('Select a slot'),
            items: [
              for (var index = 0; index < _draft.slots.length; index++)
                DropdownMenuItem(
                  value: _draft.slots[index].id,
                  child: Text(
                    'Slot ${index + 1}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (id) => setState(() => _selectedId = id),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('duplicate-slot'),
                  onPressed:
                      _saving || selected == null || _draft.slots.length >= 32
                      ? null
                      : _duplicateSlot,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Duplicate'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                key: const ValueKey('remove-slot'),
                tooltip: _draft.slots.length <= 1
                    ? 'A frame needs at least one slot'
                    : 'Remove selected slot',
                onPressed:
                    _saving || selected == null || _draft.slots.length <= 1
                    ? null
                    : _removeSlot,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (selected == null)
            const Text('Select a slot on the canvas to edit its position.')
          else ...[
            if (_draft.kind == FrameTemplateKind.flipbook)
              const Text(
                'Each slot uses the current sequence image.',
                style: TextStyle(fontSize: 13),
              )
            else
              DropdownButtonFormField<int>(
                key: ValueKey('photo-index-${selected.id}'),
                initialValue: selected.photoIndex,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Source photo'),
                items: [
                  for (var index = 0; index < 4; index++)
                    DropdownMenuItem(
                      value: index,
                      child: Text('Photo ${index + 1}'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (index) {
                        if (index != null) {
                          _changeSlot(selected.copyWith(photoIndex: index));
                        }
                      },
              ),
            const SizedBox(height: 16),
            const Text(
              'Position and size (points)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _number(
                    selected,
                    'Left',
                    selected.left,
                    (value) => selected.copyWith(left: value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _number(
                    selected,
                    'Top',
                    selected.top,
                    (value) => selected.copyWith(top: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _number(
                    selected,
                    'Width',
                    selected.width,
                    (value) => selected.copyWith(width: value),
                    positive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _number(
                    selected,
                    'Height',
                    selected.height,
                    (value) => selected.copyWith(height: value),
                    positive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _number(
              selected,
              'Rotation',
              selected.rotationDegrees,
              (value) => selected.copyWith(rotationDegrees: value),
              suffix: '°',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _changeSlot(
                            selected.copyWith(rotationDegrees: 0),
                          ),
                    icon: const Icon(Icons.rotate_left, size: 18),
                    label: const Text('Reset rotation'),
                  ),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _changeSlot(
                          selected.copyWith(
                            left: (_draft.canvasWidth - selected.width) / 2,
                            top: (_draft.canvasHeight - selected.height) / 2,
                          ),
                        ),
                  child: const Text('Center'),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          Text(
            _draft.kind == FrameTemplateKind.flipbook
                ? 'This full template is repeated as two compressed leaves '
                      'on each printed sheet.'
                : _draft.kind == FrameTemplateKind.classicPortrait
                ? 'Portrait frames are shared by Classic Portrait and '
                      'Keychain. A source photo may appear in several slots.'
                : 'A source photo may appear in several slots. Artwork is '
                      'placed above the photos; use a PNG with transparent '
                      'photo openings.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saving applies to new selections. A customer session already '
            'in progress keeps its selected frame.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF51494A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _number(
    FrameSlot slot,
    String label,
    double value,
    FrameSlot Function(double) update, {
    bool positive = false,
    String? suffix,
  }) {
    return _GeometryField(
      key: ValueKey('${slot.id}-$label'),
      label: label,
      value: value,
      enabled: !_saving,
      positive: positive,
      suffix: suffix,
      onInput: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      onChanged: (value) => _changeSlot(update(value)),
    );
  }
}

class _GeometryField extends StatefulWidget {
  final String label;
  final double value;
  final bool enabled;
  final bool positive;
  final String? suffix;
  final VoidCallback onInput;
  final ValueChanged<double> onChanged;

  const _GeometryField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onInput,
    required this.onChanged,
    this.positive = false,
    this.suffix,
  });

  @override
  State<_GeometryField> createState() => _GeometryFieldState();
}

class _GeometryFieldState extends State<_GeometryField> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );

  String _format(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  void didUpdateWidget(_GeometryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entered = double.tryParse(_controller.text);
    if (oldWidget.value != widget.value &&
        (entered == null || (entered - widget.value).abs() > 0.00001)) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('slot-${widget.label.toLowerCase()}'),
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (text) {
        final value = double.tryParse(text ?? '');
        if (value == null || !value.isFinite) return 'Enter a number.';
        if (widget.positive && value <= 0) return 'Must be above zero.';
        return null;
      },
      onChanged: (text) {
        widget.onInput();
        final value = double.tryParse(text);
        if (value != null &&
            value.isFinite &&
            (!widget.positive || value > 0)) {
          widget.onChanged(value);
        }
      },
    );
  }
}
