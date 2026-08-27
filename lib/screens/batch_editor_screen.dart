import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/box_record.dart';
import '../widgets/adaptive_action_layout.dart';
import '../widgets/ios_modal.dart';

enum BatchEditorResult { finished, viewPending }

class BatchEditorScreen extends StatefulWidget {
  const BatchEditorScreen({super.key, required this.batchId});

  final String batchId;

  @override
  State<BatchEditorScreen> createState() => _BatchEditorScreenState();
}

class _BatchEditorScreenState extends State<BatchEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _code;
  TextEditingController? _room;
  TextEditingController? _memo;
  TextEditingController? _tags;
  final _ownedControllers = <TextEditingController>[];
  String? _loadedBoxId;
  bool _saving = false;

  List<String> _split(String raw) => raw
      .split(RegExp(r'[,，]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  void _load(BoxRecord box) {
    if (_loadedBoxId == box.id) return;
    _loadedBoxId = box.id;
    _code = TextEditingController(text: box.shortCode);
    _room = TextEditingController(text: box.destinationRoom);
    _memo = TextEditingController(text: box.memo);
    _tags = TextEditingController(text: box.tags.join(', '));
    _ownedControllers.addAll([_code!, _room!, _memo!, _tags!]);
  }

  @override
  void dispose() {
    for (final controller in _ownedControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _applyToRemaining(int index) async {
    await StoreScope.of(context).applyEntryBatchDetails(
      widget.batchId,
      fromIndex: index,
      destinationRoom: _room!.text,
      tags: _split(_tags!.text),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.batchDetailsApplied)));
    }
  }

  Future<void> _next({required bool save}) async {
    if (save && !_formKey.currentState!.validate()) return;
    final store = StoreScope.of(context);
    final batch = store.entryBatchById(widget.batchId);
    if (batch == null) return;
    final index = batch.safeNextIndex;
    if (index >= batch.boxIds.length) return;
    final box = store.boxById(batch.boxIds[index]);
    if (box == null) return;
    setState(() => _saving = true);
    try {
      if (save) {
        await store.updateBox(
          box.copyWith(
            shortCode: _code!.text,
            destinationRoom: _room!.text,
            memo: _memo!.text,
            tags: _split(_tags!.text),
          ),
        );
      }
      final nextIndex = index + 1;
      await store.advanceEntryBatch(widget.batchId, nextIndex);
      if (nextIndex >= batch.boxIds.length) {
        await _finish(batch.boxIds);
      } else if (mounted) {
        setState(() => _loadedBoxId = null);
      }
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

  Future<void> _finish(List<String> boxIds) async {
    final store = StoreScope.of(context);
    final boxes = boxIds.map(store.boxById).whereType<BoxRecord>().toList();
    await store.finishEntryBatch(widget.batchId);
    if (!mounted) return;
    final viewPending = await showIosConfirmation(
      context: context,
      barrierDismissible: false,
      title: context.l10n.physicalMarkTitle,
      message:
          '${context.l10n.batchCreated(boxes.length, boxes.first.shortCode, boxes.last.shortCode)}\n\n${context.l10n.physicalMarkBatchMessage(boxes.length)}',
      cancelLabel: context.l10n.later,
      confirmLabel: context.l10n.viewPending,
    );
    if (mounted) {
      Navigator.pop(
        context,
        viewPending
            ? BatchEditorResult.viewPending
            : BatchEditorResult.finished,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final batch = store.entryBatchById(widget.batchId);
    if (batch == null || batch.boxIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.batchUnavailable)),
      );
    }
    final index = batch.safeNextIndex.clamp(0, batch.boxIds.length - 1);
    final box = store.boxById(batch.boxIds[index]);
    if (box == null) {
      return Scaffold(body: Center(child: Text(context.l10n.boxNotFound)));
    }
    _load(box);
    final isLast = index == batch.boxIds.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.batchProgress(index + 1, batch.boxIds.length)),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _applyToRemaining(index),
            child: Text(context.l10n.applyToRemaining),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (box.photoPaths.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(box.photoPaths.first),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: context.l10n.boxCode),
              validator: (value) {
                final code = (value ?? '').trim();
                if (code.isEmpty) return '';
                return store.isCodeAvailable(
                      box.projectId,
                      code,
                      excludingId: box.id,
                    )
                    ? null
                    : context.l10n.duplicateCode;
              },
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
            Text(context.l10n.applyToRemainingHint),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: AdaptiveActionLayout(
          flexes: const [1, 2],
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => _next(save: false),
              child: Text(context.l10n.skip),
            ),
            FilledButton(
              onPressed: _saving ? null : () => _next(save: true),
              child: Text(
                isLast ? context.l10n.finishBatch : context.l10n.saveAndNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
