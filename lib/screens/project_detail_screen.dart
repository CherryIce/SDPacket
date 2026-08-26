import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/box_record.dart';
import '../models/moving_project.dart';
import '../services/export_service.dart';
import '../services/photo_storage.dart';
import '../widgets/localized_values.dart';
import '../widgets/physical_mark_dialog.dart';
import '../widgets/project_form_dialog.dart';
import 'box_editor_screen.dart';
import 'pending_marks_screen.dart';
import 'qr_label_screen.dart';
import 'scanner_screen.dart';
import 'voice_entry_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _query = TextEditingController();
  final _photos = PhotoStorage();
  final _exports = const ExportService();
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openEditor(String boxId) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => BoxEditorScreen(boxId: boxId)),
    );
  }

  Future<void> _manualEntry() async {
    final box = await StoreScope.of(
      context,
    ).createBox(projectId: widget.projectId);
    if (!mounted) return;
    await _openEditor(box.id);
    if (!mounted) return;
    final current = StoreScope.of(context).boxById(box.id);
    if (current != null &&
        current.physicalMarkStatus == PhysicalMarkStatus.pending) {
      await showPhysicalMarkReminder(context, current);
    }
  }

  Future<void> _voiceEntry() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => VoiceEntryScreen(projectId: widget.projectId),
      ),
    );
    if (!mounted || result == null) return;
    if (result == 'manual') {
      await _manualEntry();
      return;
    }
    final box = StoreScope.of(context).boxById(result);
    if (box != null) {
      await _openEditor(box.id);
      if (!mounted) return;
      final current = StoreScope.of(context).boxById(box.id);
      if (current != null &&
          current.physicalMarkStatus == PhysicalMarkStatus.pending) {
        await showPhysicalMarkReminder(context, current);
      }
    }
  }

  Future<void> _photoEntry({required bool camera}) async {
    final store = StoreScope.of(context);
    setState(() => _busy = true);
    final created = <BoxRecord>[];
    try {
      final selected = camera
          ? [if (await _photos.takePhoto() case final photo?) photo]
          : await _photos.choosePhotos(limit: 30);
      for (final source in selected) {
        String? persistedPath;
        try {
          persistedPath = await _photos.persist(source);
          final box = await store.createBox(
            projectId: widget.projectId,
            photoPaths: [persistedPath],
          );
          created.add(box);
        } catch (_) {
          if (persistedPath != null) {
            await _photos.deleteIfManaged(persistedPath);
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.photoFailed)));
          }
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || created.isEmpty) return;
    if (created.length == 1) {
      await _openEditor(created.single.id);
      if (!mounted) return;
      final current = StoreScope.of(context).boxById(created.single.id);
      if (current != null &&
          current.physicalMarkStatus == PhysicalMarkStatus.pending) {
        await showPhysicalMarkReminder(context, current);
      }
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.physicalMarkTitle),
        content: Text(
          '${context.l10n.batchCreated(created.length, created.first.shortCode, created.last.shortCode)}\n\n${context.l10n.physicalMarkBatchMessage(created.length)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.later),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PendingMarksScreen(projectId: widget.projectId),
                ),
              );
            },
            child: Text(context.l10n.viewPending),
          ),
        ],
      ),
    );
  }

  Future<void> _scan() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const ScannerScreen()),
    );
    if (id != null && mounted) await _openEditor(id);
  }

  Future<void> _exportLabels() async {
    final store = StoreScope.of(context);
    final boxes = store.boxesForProject(widget.projectId).reversed.toList();
    if (boxes.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await _exports.buildLabelPdf(
        store.projectById(widget.projectId),
        boxes,
      );
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: 'moving-box-labels.pdf',
      );
      if (shared) {
        await store.markLabelExported(boxes.map((box) => box.id));
      }
      if (mounted && shared) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.labelExportedNotice)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(MovingProject project) async {
    final bytes = _exports.buildCsv(
      project,
      StoreScope.of(context).boxesForProject(project.id).reversed.toList(),
    );
    final renderBox = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: ['${project.boxPrefix}-boxes.csv'],
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      ),
    );
  }

  Future<void> _projectAction(
    _ProjectAction action,
    MovingProject project,
  ) async {
    final store = StoreScope.of(context);
    switch (action) {
      case _ProjectAction.edit:
        await showProjectFormDialog(context, project: project);
      case _ProjectAction.csv:
        await _exportCsv(project);
      case _ProjectAction.archive:
        await store.setProjectArchived(project.id, true);
        if (mounted) Navigator.pop(context);
      case _ProjectAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.delete),
            content: Text(context.l10n.deleteProjectConfirm),
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
        final paths = store
            .boxesForProject(project.id)
            .expand((box) => box.photoPaths)
            .toList();
        await store.deleteProject(project.id);
        for (final path in paths) {
          await _photos.deleteIfManaged(path);
        }
        if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final project = store.projectById(widget.projectId);
    final boxes = store.boxesForProject(widget.projectId, query: _query.text);
    final stats = store.statsFor(widget.projectId);
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: context.l10n.scan,
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
          ),
          PopupMenuButton<_ProjectAction>(
            onSelected: (action) => _projectAction(action, project),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ProjectAction.edit,
                child: Text(context.l10n.editProject),
              ),
              PopupMenuItem(
                value: _ProjectAction.csv,
                child: Text(context.l10n.exportCsv),
              ),
              PopupMenuItem(
                value: _ProjectAction.archive,
                child: Text(context.l10n.archive),
              ),
              PopupMenuItem(
                value: _ProjectAction.delete,
                child: Text(context.l10n.delete),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _ProgressCard(stats: stats),
            if (stats.pendingMarks > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(
                    '${context.l10n.pendingPhysicalMark} · ${stats.pendingMarks}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PendingMarksScreen(projectId: project.id),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              context.l10n.quickEntry,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _QuickEntryGrid(
              busy: _busy,
              onCamera: () => _photoEntry(camera: true),
              onGallery: () => _photoEntry(camera: false),
              onVoice: _voiceEntry,
              onManual: _manualEntry,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportLabels,
              icon: const Icon(Icons.print_outlined),
              label: Text(context.l10n.exportA4Pdf),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.l10n.searchBoxes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_query.clear),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.boxes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(context.l10n.boxCount(boxes.length)),
              ],
            ),
            const SizedBox(height: 10),
            if (boxes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text(context.l10n.noResults)),
              )
            else
              ...boxes.map(
                (box) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BoxCard(
                    box: box,
                    onTap: () => _openEditor(box.id),
                    onQr: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => QrLabelScreen(boxId: box.id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats});

  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (context.l10n.total, stats.total, Icons.inventory_2_outlined),
      (context.l10n.packed, stats.packed, Icons.check_box_outlined),
      (context.l10n.loaded, stats.loaded, Icons.local_shipping_outlined),
      (context.l10n.arrived, stats.arrived, Icons.location_on_outlined),
      (context.l10n.unpacked, stats.unpacked, Icons.unarchive_outlined),
      (
        context.l10n.suspectedMissing,
        stats.suspectedMissing,
        Icons.warning_amber,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.progress,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 64) / 3,
                      child: Column(
                        children: [
                          Icon(metric.$3, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${metric.$2}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            metric.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickEntryGrid extends StatelessWidget {
  const _QuickEntryGrid({
    required this.busy,
    required this.onCamera,
    required this.onGallery,
    required this.onVoice,
    required this.onManual,
  });

  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVoice;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (context.l10n.takePhoto, Icons.camera_alt_outlined, onCamera),
      (context.l10n.choosePhotos, Icons.photo_library_outlined, onGallery),
      (context.l10n.voiceEntry, Icons.mic_none, onVoice),
      (context.l10n.manualEntry, Icons.edit_note, onManual),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.45,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: entries
          .map(
            (entry) => FilledButton.tonalIcon(
              onPressed: busy ? null : entry.$3,
              icon: Icon(entry.$2),
              label: Text(entry.$1, textAlign: TextAlign.center),
            ),
          )
          .toList(),
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({required this.box, required this.onTap, required this.onQr});

  final BoxRecord box;
  final VoidCallback onTap;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    final summary = [
      box.destinationRoom,
      box.memo,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 64,
                  child: box.photoPaths.isEmpty
                      ? ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.inventory_2_outlined),
                        )
                      : Image.file(
                          File(box.photoPaths.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          box.shortCode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(box: box),
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (box.physicalMarkStatus ==
                        PhysicalMarkStatus.pending) ...[
                      const SizedBox(height: 5),
                      Text(
                        context.l10n.pendingPhysicalMark,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.qrAndPrint,
                onPressed: onQr,
                icon: const Icon(Icons.qr_code_2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.box});

  final BoxRecord box;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        box.moveStatus.label(context),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

enum _ProjectAction { edit, csv, archive, delete }
