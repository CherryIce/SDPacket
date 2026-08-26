import 'package:flutter/material.dart';

import '../app.dart';
import '../models/box_record.dart';
import 'localized_values.dart';

Future<void> showPhysicalMarkReminder(
  BuildContext context,
  BoxRecord box,
) async {
  final method = await showModalBottomSheet<PhysicalMarkMethod>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.physicalMarkTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.physicalMarkMessage(box.shortCode)),
            const SizedBox(height: 18),
            ...PhysicalMarkMethod.values.map(
              (value) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_methodIcon(value)),
                title: Text(value.label(context)),
                onTap: () => Navigator.pop(context, value),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.later),
            ),
          ],
        ),
      ),
    ),
  );
  if (method != null && context.mounted) {
    await StoreScope.of(context).confirmPhysicalMark(box.id, method);
  }
}

IconData _methodIcon(PhysicalMarkMethod method) => switch (method) {
  PhysicalMarkMethod.qrLabel => Icons.qr_code_2,
  PhysicalMarkMethod.handwritten => Icons.edit_outlined,
  PhysicalMarkMethod.stickyNote => Icons.sticky_note_2_outlined,
  PhysicalMarkMethod.other => Icons.label_outline,
};
