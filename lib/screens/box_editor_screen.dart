import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/box_record.dart';
import '../services/photo_storage.dart';
import '../widgets/ios_modal.dart';
import '../widgets/localized_values.dart';
import '../widgets/physical_mark_dialog.dart';
import 'qr_label_screen.dart';

class BoxEditorScreen extends StatefulWidget {
  const BoxEditorScreen({Key? key, required String boxId})
    : this._(key: key, boxId: boxId);

  const BoxEditorScreen.create({Key? key, required String projectId})
    : this._(key: key, projectId: projectId);

  const BoxEditorScreen._({super.key, this.boxId, this.projectId})
    : assert((boxId == null) != (projectId == null));

  final String? boxId;
  final String? projectId;

  @override
  State<BoxEditorScreen> createState() => _BoxEditorScreenState();
}

class _BoxEditorScreenState extends State<BoxEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoStorage = PhotoStorage();
  final _newPhotoPaths = <String>{};
  final _removedPhotoPaths = <String>{};
  late BoxRecord _box;
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _room;
  late final TextEditingController _location;
  late final TextEditingController _memo;
  late final TextEditingController _tags;
  late List<BoxItem> _items;
  late List<String> _photoPaths;
  late MoveStatus _status;
  late Set<BoxIssue> _issues;
  late bool _priority;
  bool _saving = false;
  bool _saved = false;

  bool _initialized = false;

  bool get _isNew => widget.boxId == null;

  void _initializeIfNeeded() {
    if (_initialized) return;
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final record = _isNew
        ? BoxRecord(
            id: '',
            projectId: widget.projectId!,
            shortCode: store.nextCode(widget.projectId!),
            createdAt: now,
            updatedAt: now,
          )
        : store.boxById(widget.boxId!);
    if (record == null) throw StateError('Box not found');
    _box = record;
    _code = TextEditingController(text: record.shortCode);
    _title = TextEditingController(text: record.title);
    _room = TextEditingController(text: record.destinationRoom);
    _location = TextEditingController(text: record.currentLocation);
    _memo = TextEditingController(text: record.memo);
    _tags = TextEditingController(text: record.tags.join(', '));
    _items = record.items.toList();
    _photoPaths = record.photoPaths.toList();
    _status = record.moveStatus;
    _issues = record.issues.toSet();
    _priority = record.isPriority;
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _code.dispose();
      _title.dispose();
      _room.dispose();
      _location.dispose();
      _memo.dispose();
      _tags.dispose();
    }
    if (!_saved) {
      for (final path in _newPhotoPaths) {
        unawaited(_photoStorage.deleteIfManaged(path));
      }
    }
    super.dispose();
  }

  List<String> _split(String raw) => raw
      .split(RegExp(r'[,，]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  void _toggleTag(String tag) {
    final tags = _split(_tags.text);
    final index = tags.indexWhere(
      (value) => value.toLowerCase() == tag.toLowerCase(),
    );
    if (index < 0) {
      tags.add(tag);
    } else {
      tags.removeAt(index);
    }
    _setControllerText(_tags, tags.join(', '));
  }

  void _setControllerText(TextEditingController controller, String value) {
    setState(() {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });
  }

  Future<void> _editItem([BoxItem? existing]) async {
    final result = await showIosFormSheet<BoxItem>(
      context: context,
      builder: (_) => _ItemEditorDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _undoLastStatus() async {
    final store = StoreScope.of(context);
    await store.undoLastStatusChange(_box.id);
    if (!mounted) return;
    final current = store.boxById(_box.id);
    if (current == null) return;
    setState(() {
      _box = current;
      _status = current.moveStatus;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.statusUndoSuccess)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = StoreScope.of(context);
    try {
      if (_isNew) {
        _box = await store.createBox(
          projectId: _box.projectId,
          shortCode: _code.text,
          title: _title.text,
          destinationRoom: _room.text,
          currentLocation: _location.text,
          memo: _memo.text,
          tags: _split(_tags.text),
          items: _items,
          photoPaths: _photoPaths,
          isPriority: _priority,
          moveStatus: _status,
          issues: _issues,
        );
      } else {
        final current = store.boxById(_box.id) ?? _box;
        final updated = current.copyWith(
          shortCode: _code.text,
          title: _title.text,
          destinationRoom: _room.text,
          currentLocation: _location.text,
          memo: _memo.text,
          tags: _split(_tags.text),
          items: _items,
          photoPaths: _photoPaths,
          isPriority: _priority,
          moveStatus: _status,
          issues: _issues,
        );
        await store.updateBox(updated);
        _box = store.boxById(_box.id) ?? updated;
      }
      for (final path in _removedPhotoPaths) {
        await _photoStorage.deleteIfManaged(path);
      }
      _saved = true;
      _newPhotoPaths.clear();
      _removedPhotoPaths.clear();
      if (mounted) Navigator.pop(context, _box.id);
    } on DuplicateBoxCodeException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.duplicateCode)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPhoto() async {
    final selected = await showIosActionSheet<_PhotoSource>(
      context: context,
      cancelLabel: context.l10n.cancel,
      options: [
        IosActionSheetOption(
          label: context.l10n.camera,
          value: _PhotoSource.camera,
        ),
        IosActionSheetOption(
          label: context.l10n.gallery,
          value: _PhotoSource.gallery,
        ),
      ],
    );
    if (selected == null) return;
    try {
      final source = selected == _PhotoSource.camera
          ? await _photoStorage.takePhoto()
          : (await _photoStorage.choosePhotos(limit: 1)).firstOrNull;
      if (source == null) return;
      final path = await _photoStorage.persist(source);
      if (!mounted) return;
      setState(() {
        _photoPaths.add(path);
        _newPhotoPaths.add(path);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.photoFailed)));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showIosConfirmation(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.deleteBoxConfirm,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await StoreScope.of(context).deleteBox(_box.id);
    for (final path in {..._box.photoPaths, ..._newPhotoPaths}) {
      await _photoStorage.deleteIfManaged(path);
    }
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _initializeIfNeeded();
    final store = StoreScope.of(context);
    final roomSuggestions = _uniqueSuggestions([
      ...store.recentRoomsForProject(_box.projectId),
      context.l10n.templateKitchen,
      context.l10n.templateBedroom,
    ]);
    final locationSuggestions = _uniqueSuggestions([
      ...store.recentLocationsForProject(_box.projectId),
      context.l10n.templateOldHome,
      context.l10n.templateNewHome,
      context.l10n.templateStorage,
    ]);
    final tagSuggestions = _uniqueSuggestions([
      ...store.recentTagsForProject(_box.projectId),
      context.l10n.templateFragile,
      context.l10n.templateKeepDry,
      context.l10n.templateUnpackFirst,
    ]);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? context.l10n.manualEntry : _box.shortCode),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: context.l10n.delete,
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const Key('box-editor-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _EditorSection(
              key: const Key('box-editor-information-section'),
              icon: Icons.inventory_2_outlined,
              title: context.l10n.boxInformation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photoPaths.isNotEmpty) ...[
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photoPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_photoPaths[index]),
                                width: 132,
                                height: 132,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: IconButton.filledTonal(
                                tooltip: context.l10n.removePhoto,
                                onPressed: () {
                                  final path = _photoPaths[index];
                                  setState(() => _photoPaths.removeAt(index));
                                  if (_newPhotoPaths.remove(path)) {
                                    unawaited(
                                      _photoStorage.deleteIfManaged(path),
                                    );
                                  } else {
                                    _removedPhotoPaths.add(path);
                                  }
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(context.l10n.addPhoto),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('box-editor-code'),
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: context.l10n.boxCode,
                    ),
                    validator: (value) {
                      final code = (value ?? '').trim();
                      if (code.isEmpty) return '';
                      return StoreScope.of(context).isCodeAvailable(
                            _box.projectId,
                            code,
                            excludingId: _isNew ? null : _box.id,
                          )
                          ? null
                          : context.l10n.duplicateCode;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: context.l10n.boxTitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _room,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.destinationRoom,
                    ),
                  ),
                  _SuggestionChips(
                    values: roomSuggestions,
                    selectedValues: [_room.text],
                    onSelected: (value) => _setControllerText(_room, value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _location,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.currentLocation,
                    ),
                  ),
                  _SuggestionChips(
                    values: locationSuggestions,
                    selectedValues: [_location.text],
                    onSelected: (value) => _setControllerText(_location, value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _EditorSection(
              key: const Key('box-editor-contents-section'),
              icon: Icons.notes_outlined,
              title: context.l10n.contentsAndNotes,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _memo,
                    minLines: 3,
                    maxLines: 7,
                    decoration: InputDecoration(labelText: context.l10n.memo),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('box-editor-tags'),
                    controller: _tags,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.tags,
                      hintText: context.l10n.tagsHint,
                    ),
                  ),
                  _SuggestionChips(
                    values: tagSuggestions,
                    selectedValues: _split(_tags.text),
                    onSelected: _toggleTag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _EditorSection(
              key: const Key('box-editor-items-section'),
              icon: Icons.category_outlined,
              title: context.l10n.items,
              trailing: TextButton.icon(
                onPressed: () => _editItem(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addItem),
              ),
              child: _items.isEmpty
                  ? Text(
                      context.l10n.noStructuredItems,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      children: _items.indexed.map((indexed) {
                        final index = indexed.$1;
                        final item = indexed.$2;
                        final details = [
                          if (item.quantity != null)
                            context.l10n.itemQuantityValue(item.quantity!),
                          item.note,
                        ].where((value) => value.isNotEmpty).join(' · ');
                        return Column(
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: item.isUnpacked,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(item.name),
                              subtitle: details.isEmpty ? null : Text(details),
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: context.l10n.edit,
                                    onPressed: () => _editItem(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: context.l10n.delete,
                                    onPressed: () =>
                                        setState(() => _items.removeAt(index)),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              onChanged: (value) => setState(() {
                                _items[index] = item.copyWith(
                                  isUnpacked: value ?? false,
                                );
                              }),
                            ),
                            if (index != _items.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _EditorSection(
              key: const Key('box-editor-moving-section'),
              icon: Icons.local_shipping_outlined,
              title: context.l10n.movingAndFlags,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.priority),
                    value: _priority,
                    onChanged: (value) => setState(() => _priority = value),
                  ),
                  const SizedBox(height: 4),
                  IosSelectionField<MoveStatus>(
                    key: ValueKey(_status),
                    label: context.l10n.moveStatus,
                    value: _status,
                    valueLabel: _status.label(context),
                    cancelLabel: context.l10n.cancel,
                    options: MoveStatus.values
                        .map(
                          (status) => IosActionSheetOption(
                            label: status.label(context),
                            value: status,
                          ),
                        )
                        .toList(),
                    onSelected: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.issues,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BoxIssue.values
                        .map(
                          (issue) => FilterChip(
                            selected: _issues.contains(issue),
                            label: Text(issue.label(context)),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _issues.add(issue)
                                  : _issues.remove(issue);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 14),
              _StatusHistoryCard(box: _box, onUndo: _undoLastStatus),
              const SizedBox(height: 14),
              _EditorSection(
                key: const Key('box-editor-mark-section'),
                icon: Icons.label_outline,
                title: context.l10n.physicalMark,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.label_outline),
                      title: Text(context.l10n.physicalMark),
                      subtitle: Text(
                        _box.physicalMarkStatus == PhysicalMarkStatus.pending
                            ? context.l10n.pendingPhysicalMark
                            : (_box.physicalMarkMethod?.label(context) ??
                                  context.l10n.marked),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await showPhysicalMarkReminder(context, _box);
                        if (mounted) {
                          setState(() {
                            _box =
                                StoreScope.of(context).boxById(_box.id) ?? _box;
                          });
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(context.l10n.qrAndPrint),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => QrLabelScreen(boxId: _box.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton(
            key: const Key('box-editor-save'),
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.save),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            Theme(
              data: theme.copyWith(
                inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                  fillColor: colors.surfaceContainerLow,
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({this.existing});

  final BoxItem? existing;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _noteFocus = FocusNode();
  final _nameAnchor = GlobalKey();
  final _quantityAnchor = GlobalKey();
  final _noteAnchor = GlobalKey();
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _quantity = TextEditingController(
    text: widget.existing?.quantity?.toString() ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final focusNode in _focusNodes) {
      focusNode.addListener(_scheduleFocusedFieldReveal);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final focusNode in _focusNodes) {
      focusNode.removeListener(_scheduleFocusedFieldReveal);
      focusNode.dispose();
    }
    _name.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  List<FocusNode> get _focusNodes => [_nameFocus, _quantityFocus, _noteFocus];

  @override
  void didChangeMetrics() {
    _scheduleFocusedFieldReveal();
  }

  GlobalKey? get _focusedAnchor {
    if (_nameFocus.hasFocus) return _nameAnchor;
    if (_quantityFocus.hasFocus) return _quantityAnchor;
    if (_noteFocus.hasFocus) return _noteAnchor;
    return null;
  }

  void _scheduleFocusedFieldReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _focusedAnchor?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BoxItem(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        quantity: _quantity.text.trim().isEmpty
            ? null
            : int.parse(_quantity.text.trim()),
        note: _note.text.trim(),
        isUnpacked: widget.existing?.isUnpacked ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const scrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 100);
    return IosFormSheet(
      title: widget.existing == null
          ? context.l10n.addItem
          : context.l10n.editItem,
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: _nameAnchor,
                child: TextFormField(
                  key: const Key('item-name-field'),
                  controller: _name,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.itemName,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? context.l10n.itemNameRequired
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _quantityAnchor,
                child: TextFormField(
                  key: const Key('item-quantity-field'),
                  controller: _quantity,
                  focusNode: _quantityFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.itemQuantity,
                  ),
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) return null;
                    final parsed = int.tryParse(raw);
                    return parsed == null || parsed <= 0
                        ? context.l10n.itemQuantityInvalid
                        : null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _noteAnchor,
                child: TextField(
                  key: const Key('item-note-field'),
                  controller: _note,
                  focusNode: _noteFocus,
                  minLines: 2,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.itemNote,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IosFormDialogAction(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        IosFormDialogAction(
          label: context.l10n.save,
          isDefaultAction: true,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.values,
    required this.selectedValues,
    required this.onSelected,
  });

  final List<String> values;
  final List<String> selectedValues;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.quickTemplates,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((value) {
              final selected = selectedValues.any(
                (selectedValue) =>
                    selectedValue.toLowerCase() == value.toLowerCase(),
              );
              return FilterChip(
                key: ValueKey('suggestion-$value'),
                visualDensity: VisualDensity.compact,
                selected: selected,
                label: Text(value),
                onSelected: (_) => onSelected(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({required this.box, required this.onUndo});

  final BoxRecord box;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final history = box.statusHistory.reversed.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.statusHistory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: onUndo,
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(context.l10n.undoLastStatus),
                  ),
              ],
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(context.l10n.noStatusHistory),
              )
            else
              ...history.map((entry) {
                final material = MaterialLocalizations.of(context);
                final date = material.formatCompactDate(entry.changedAt);
                final time = material.formatTimeOfDay(
                  TimeOfDay.fromDateTime(entry.changedAt),
                );
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${entry.from.label(context)} → ${entry.to.label(context)}',
                  ),
                  subtitle: Text(
                    '${entry.source.label(context)} · $date $time',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

List<String> _uniqueSuggestions(Iterable<String> values) {
  final seen = <String>{};
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
      .toList(growable: false);
}

enum _PhotoSource { camera, gallery }
