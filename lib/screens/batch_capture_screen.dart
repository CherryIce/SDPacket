import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/box_record.dart';
import '../services/photo_storage.dart';
import '../widgets/adaptive_action_layout.dart';
import 'batch_editor_screen.dart';

class BatchCaptureScreen extends StatefulWidget {
  const BatchCaptureScreen({
    super.key,
    required this.projectId,
    required this.batchId,
  });

  final String projectId;
  final String batchId;

  @override
  State<BatchCaptureScreen> createState() => _BatchCaptureScreenState();
}

class _BatchCaptureScreenState extends State<BatchCaptureScreen> {
  final _photos = PhotoStorage();
  bool _busy = false;
  bool _closing = false;

  Future<void> _capture() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? persistedPath;
    try {
      final photo = await _photos.takePhoto();
      if (photo == null) return;
      persistedPath = await _photos.persist(photo);
      if (!mounted) {
        await _photos.deleteIfManaged(persistedPath);
        return;
      }
      await StoreScope.of(context).createBox(
        projectId: widget.projectId,
        photoPaths: [persistedPath],
        entryBatchId: widget.batchId,
      );
    } catch (_) {
      if (persistedPath != null) {
        await _photos.deleteIfManaged(persistedPath);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.photoFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    final result = await Navigator.push<BatchEditorResult>(
      context,
      MaterialPageRoute<BatchEditorResult>(
        builder: (_) => BatchEditorScreen(batchId: widget.batchId),
      ),
    );
    if (mounted && result != null) Navigator.pop(context, result);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await StoreScope.of(context).discardEmptyEntryBatch(widget.batchId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final batch = store.entryBatchById(widget.batchId);
    final boxes = batch == null
        ? const <BoxRecord>[]
        : batch.boxIds.map(store.boxById).whereType<BoxRecord>().toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => unawaited(_close()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _busy ? null : _close,
            icon: const Icon(Icons.close),
          ),
          title: Text(context.l10n.continuousCamera),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.batchCaptureCount(boxes.length),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(context.l10n.batchCaptureHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (boxes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.add_a_photo_outlined, size: 54),
                    const SizedBox(height: 12),
                    Text(context.l10n.noBatchPhotos),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: boxes.length,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(boxes[index].photoPaths.first),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(boxes[index].shortCode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: AdaptiveActionLayout(
            children: [
              OutlinedButton.icon(
                onPressed: _busy || boxes.isEmpty ? null : _review,
                icon: const Icon(Icons.edit_note),
                label: Text(context.l10n.editBatch),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _capture,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(context.l10n.takeNextPhoto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
