import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/box_record.dart';
import '../widgets/physical_mark_dialog.dart';

class PendingMarksScreen extends StatelessWidget {
  const PendingMarksScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final boxes = store
        .boxesForProject(projectId)
        .where((box) => box.physicalMarkStatus == PhysicalMarkStatus.pending)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pendingPhysicalMark)),
      body: boxes.isEmpty
          ? Center(child: Text(context.l10n.noPending))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: boxes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final box = boxes[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _Thumbnail(path: box.photoPaths.firstOrNull),
                    title: Text(
                      box.shortCode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      [
                        box.destinationRoom,
                        box.memo,
                      ].where((value) => value.isNotEmpty).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => showPhysicalMarkReminder(context, box),
                      child: Text(context.l10n.markConfirmed),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 52,
        child: path == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.inventory_2_outlined),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}
