import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/box_record.dart';
import '../models/entry_batch.dart';
import '../models/moving_project.dart';
import '../services/export_service.dart';
import '../services/photo_storage.dart';
import '../widgets/ios_modal.dart';
import '../widgets/localized_values.dart';
import '../widgets/physical_mark_dialog.dart';
import '../widgets/project_form_dialog.dart';
import 'batch_capture_screen.dart';
import 'batch_editor_screen.dart';
import 'box_editor_screen.dart';
import 'moving_scan_screen.dart';
import 'pending_marks_screen.dart';
import 'qr_label_screen.dart';
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
  final _stageFilters = <_StageFilter>{};
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
    final existingBatch = store.activeEntryBatchForProject(widget.projectId);
    if (existingBatch != null) {
      await _openBatchEditor(existingBatch.id);
      return;
    }
    if (camera) {
      final batch = await store.createEntryBatch(
        projectId: widget.projectId,
        source: EntryBatchSource.camera,
      );
      if (!mounted) return;
      final result = await Navigator.push<BatchEditorResult>(
        context,
        MaterialPageRoute<BatchEditorResult>(
          builder: (_) => BatchCaptureScreen(
            projectId: widget.projectId,
            batchId: batch.id,
          ),
        ),
      );
      if (mounted) await _handleBatchResult(result);
      return;
    }
    setState(() => _busy = true);
    final created = <BoxRecord>[];
    late final EntryBatch batch;
    try {
      final selected = await _photos.choosePhotos(limit: 30);
      if (selected.isEmpty) return;
      batch = await store.createEntryBatch(
        projectId: widget.projectId,
        source: EntryBatchSource.gallery,
      );
      for (final source in selected) {
        String? persistedPath;
        try {
          persistedPath = await _photos.persist(source);
          final box = await store.createBox(
            projectId: widget.projectId,
            photoPaths: [persistedPath],
            entryBatchId: batch.id,
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
    if (!mounted) return;
    if (created.isEmpty) {
      await store.discardEmptyEntryBatch(batch.id);
      return;
    }
    await _openBatchEditor(batch.id);
  }

  Future<void> _openBatchEditor(String batchId) async {
    final result = await Navigator.push<BatchEditorResult>(
      context,
      MaterialPageRoute<BatchEditorResult>(
        builder: (_) => BatchEditorScreen(batchId: batchId),
      ),
    );
    if (mounted) await _handleBatchResult(result);
  }

  Future<void> _handleBatchResult(BatchEditorResult? result) async {
    if (result != BatchEditorResult.viewPending || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PendingMarksScreen(projectId: widget.projectId),
      ),
    );
  }

  Future<void> _scan() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MovingScanScreen(projectId: widget.projectId),
      ),
    );
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
        BoxLabelPdfLabels(
          documentTitle: context.l10n.labelDocumentTitle,
          brand: context.l10n.labelBrand,
          scanOrSearchCode: context.l10n.scanOrSearchCode,
        ),
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

  Future<void> _exportReport(MovingProject project) async {
    final material = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final generatedAt =
        '${material.formatFullDate(now)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(now))}';
    setState(() => _busy = true);
    try {
      final bytes = await _exports.buildProjectReportPdf(
        project: project,
        boxes: StoreScope.of(context).boxesForProject(project.id),
        labels: ProjectReportLabels(
          title: context.l10n.projectReport,
          generatedAt: context.l10n.reportGeneratedAt(generatedAt),
          total: context.l10n.total,
          suspectedMissing: context.l10n.suspectedMissing,
          damaged: context.l10n.reportDamaged,
          notUnpacked: context.l10n.notUnpacked,
          roomDistribution: context.l10n.roomDistribution,
          none: context.l10n.reportNone,
          unassignedRoom: context.l10n.unassignedRoom,
          moreRooms: context.l10n.moreRooms,
        ),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${project.boxPrefix}-project-report.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.exportFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      case _ProjectAction.report:
        await _exportReport(project);
      case _ProjectAction.archive:
        await store.setProjectArchived(project.id, true);
        if (mounted) Navigator.pop(context);
      case _ProjectAction.delete:
        final confirmed = await showIosConfirmation(
          context: context,
          title: context.l10n.delete,
          message: context.l10n.deleteProjectConfirm,
          cancelLabel: context.l10n.cancel,
          confirmLabel: context.l10n.delete,
          isDestructive: true,
        );
        if (!confirmed || !mounted) return;
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

  Future<void> _showProjectActions(MovingProject project) async {
    final action = await showIosActionSheet<_ProjectAction>(
      context: context,
      cancelLabel: context.l10n.cancel,
      options: [
        IosActionSheetOption(
          label: context.l10n.editProject,
          value: _ProjectAction.edit,
          icon: Icons.edit_outlined,
        ),
        IosActionSheetOption(
          label: context.l10n.exportCsv,
          value: _ProjectAction.csv,
          icon: Icons.table_view_outlined,
        ),
        IosActionSheetOption(
          label: context.l10n.projectReport,
          value: _ProjectAction.report,
          icon: Icons.picture_as_pdf_outlined,
        ),
        IosActionSheetOption(
          label: context.l10n.archive,
          value: _ProjectAction.archive,
          icon: Icons.archive_outlined,
        ),
        IosActionSheetOption(
          label: context.l10n.delete,
          value: _ProjectAction.delete,
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
      ],
    );
    if (action != null && mounted) await _projectAction(action, project);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final project = store.projectById(widget.projectId);
    final allMatchingBoxes = store.boxesForProject(
      widget.projectId,
      query: _query.text,
    );
    final boxes = _stageFilters.isEmpty
        ? allMatchingBoxes
        : allMatchingBoxes.where(_matchesSelectedStage).toList();
    final stats = store.statsFor(widget.projectId);
    final activeBatch = store.activeEntryBatchForProject(widget.projectId);
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: context.l10n.movingScanMode,
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: context.l10n.moreActions,
            onPressed: _busy ? null : () => _showProjectActions(project),
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _ProgressCard(
              stats: stats,
              selected: _stageFilters,
              onToggle: (filter) => setState(() {
                _stageFilters.contains(filter)
                    ? _stageFilters.remove(filter)
                    : _stageFilters.add(filter);
              }),
              onClear: () => setState(_stageFilters.clear),
            ),
            if (activeBatch != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.pending_actions_outlined),
                  title: Text(context.l10n.resumeBatch),
                  subtitle: Text(
                    context.l10n.batchProgress(
                      activeBatch.safeNextIndex + 1,
                      activeBatch.boxIds.length,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openBatchEditor(activeBatch.id),
                ),
              ),
            ],
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

bool _matchesStage(BoxRecord box, _StageFilter filter) => switch (filter) {
  _StageFilter.waitingToLoad => box.moveStatus.index < MoveStatus.loaded.index,
  _StageFilter.notArrived => box.moveStatus.index < MoveStatus.arrived.index,
  _StageFilter.notUnpacked => box.moveStatus.index < MoveStatus.unpacked.index,
  _StageFilter.suspectedMissing => box.issues.contains(
    BoxIssue.suspectedMissing,
  ),
};

extension on _ProjectDetailScreenState {
  bool _matchesSelectedStage(BoxRecord box) =>
      _stageFilters.any((filter) => _matchesStage(box, filter));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.stats,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final ProjectStats stats;
  final Set<_StageFilter> selected;
  final ValueChanged<_StageFilter> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final metrics = <(_StageFilter, String, int, IconData)>[
      (
        _StageFilter.waitingToLoad,
        context.l10n.waitingToLoad,
        stats.waitingToLoad,
        Icons.inventory_2_outlined,
      ),
      (
        _StageFilter.notArrived,
        context.l10n.notArrived,
        stats.notArrived,
        Icons.local_shipping_outlined,
      ),
      (
        _StageFilter.notUnpacked,
        context.l10n.notUnpacked,
        stats.notUnpacked,
        Icons.unarchive_outlined,
      ),
      (
        _StageFilter.suspectedMissing,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.progress,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(context.l10n.boxCount(stats.total)),
              ],
            ),
            const SizedBox(height: 4),
            Text(context.l10n.stageFilterHint),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics
                  .map(
                    (metric) => FilterChip(
                      selected: selected.contains(metric.$1),
                      avatar: Icon(metric.$4, size: 18),
                      label: Text('${metric.$2} ${metric.$3}'),
                      onSelected: (_) => onToggle(metric.$1),
                    ),
                  )
                  .toList(),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(context.l10n.clearFilters),
                ),
              ),
            ],
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
      (context.l10n.continuousCamera, Icons.camera_alt_outlined, onCamera),
      (context.l10n.choosePhotos, Icons.photo_library_outlined, onGallery),
      (context.l10n.voiceEntry, Icons.mic_none, onVoice),
      (context.l10n.manualEntry, Icons.edit_note, onManual),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final entryHeight = (64 + (textScale - 1).clamp(0, 1) * 32).toDouble();
    return GridView.builder(
      itemCount: entries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: entryHeight,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return FilledButton.tonal(
          onPressed: busy ? null : entry.$3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entry.$2),
              const SizedBox(width: 8),
              Flexible(child: Text(entry.$1, textAlign: TextAlign.center)),
            ],
          ),
        );
      },
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

enum _ProjectAction { edit, csv, report, archive, delete }

enum _StageFilter { waitingToLoad, notArrived, notUnpacked, suspectedMissing }
