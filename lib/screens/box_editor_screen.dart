import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/box_record.dart';
import '../services/photo_storage.dart';
import '../widgets/localized_values.dart';
import '../widgets/physical_mark_dialog.dart';
import 'qr_label_screen.dart';

class BoxEditorScreen extends StatefulWidget {
  const BoxEditorScreen({super.key, required this.boxId});

  final String boxId;

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
  late final TextEditingController _items;
  late List<String> _photoPaths;
  late MoveStatus _status;
  late Set<BoxIssue> _issues;
  late bool _priority;
  bool _saving = false;
  bool _saved = false;

  bool _initialized = false;

  void _initializeIfNeeded() {
    if (_initialized) return;
    final record = StoreScope.of(context).boxById(widget.boxId);
    if (record == null) throw StateError('Box not found');
    _box = record;
    _code = TextEditingController(text: record.shortCode);
    _title = TextEditingController(text: record.title);
    _room = TextEditingController(text: record.destinationRoom);
    _location = TextEditingController(text: record.currentLocation);
    _memo = TextEditingController(text: record.memo);
    _tags = TextEditingController(text: record.tags.join(', '));
    _items = TextEditingController(
      text: record.items.map((item) => item.name).join(', '),
    );
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
      _items.dispose();
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
      .toList(growable: false);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = StoreScope.of(context);
    final current = store.boxById(_box.id) ?? _box;
    final itemNames = _split(_items.text);
    final existingByName = {
      for (final item in current.items) item.name.toLowerCase(): item,
    };
    final items = itemNames
        .map(
          (name) =>
              existingByName[name.toLowerCase()] ??
              BoxItem(id: const Uuid().v4(), name: name),
        )
        .toList();
    final updated = current.copyWith(
      shortCode: _code.text,
      title: _title.text,
      destinationRoom: _room.text,
      currentLocation: _location.text,
      memo: _memo.text,
      tags: _split(_tags.text),
      items: items,
      photoPaths: _photoPaths,
      isPriority: _priority,
      moveStatus: _status,
      issues: _issues,
    );
    try {
      await store.updateBox(updated);
      for (final path in _removedPhotoPaths) {
        await _photoStorage.deleteIfManaged(path);
      }
      _saved = true;
      _newPhotoPaths.clear();
      _removedPhotoPaths.clear();
      if (mounted) Navigator.pop(context, true);
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
    final selected = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.camera),
              onTap: () => Navigator.pop(context, _PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.gallery),
              onTap: () => Navigator.pop(context, _PhotoSource.gallery),
            ),
          ],
        ),
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text(context.l10n.deleteBoxConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await StoreScope.of(context).deleteBox(_box.id);
    for (final path in {..._box.photoPaths, ..._newPhotoPaths}) {
      await _photoStorage.deleteIfManaged(path);
    }
    _saved = true;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    _initializeIfNeeded();
    return Scaffold(
      appBar: AppBar(
        title: Text(_box.shortCode),
        actions: [
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (_photoPaths.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_photoPaths[index]),
                          width: 150,
                          height: 150,
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
                              unawaited(_photoStorage.deleteIfManaged(path));
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
            OutlinedButton.icon(
              onPressed: _addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(context.l10n.addPhoto),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: context.l10n.boxCode),
              validator: (value) {
                final code = (value ?? '').trim();
                if (code.isEmpty) return '';
                return StoreScope.of(context).isCodeAvailable(
                      _box.projectId,
                      code,
                      excludingId: _box.id,
                    )
                    ? null
                    : context.l10n.duplicateCode;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: context.l10n.boxTitle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _room,
              decoration: InputDecoration(
                labelText: context.l10n.destinationRoom,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: context.l10n.currentLocation,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memo,
              minLines: 3,
              maxLines: 7,
              decoration: InputDecoration(labelText: context.l10n.memo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: InputDecoration(
                labelText: context.l10n.tags,
                hintText: context.l10n.tagsHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _items,
              decoration: InputDecoration(
                labelText: context.l10n.items,
                hintText: context.l10n.itemsHint,
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.priority),
              value: _priority,
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MoveStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: context.l10n.moveStatus),
              items: MoveStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.issues,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BoxIssue.values
                  .map(
                    (issue) => FilterChip(
                      selected: _issues.contains(issue),
                      label: Text(issue.label(context)),
                      onSelected: (selected) => setState(() {
                        selected ? _issues.add(issue) : _issues.remove(issue);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
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
                      _box = StoreScope.of(context).boxById(_box.id) ?? _box;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _saving
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Text(context.l10n.save),
          ),
        ),
      ),
    );
  }
}

enum _PhotoSource { camera, gallery }
