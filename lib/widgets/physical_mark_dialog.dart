import 'package:flutter/material.dart';

import '../app.dart';
import '../models/box_record.dart';
import 'ios_modal.dart';
import 'localized_values.dart';

Future<void> showPhysicalMarkReminder(
  BuildContext context,
  BoxRecord box,
) async {
  final method = await showIosActionSheet<PhysicalMarkMethod>(
    context: context,
    title: context.l10n.physicalMarkTitle,
    message: context.l10n.physicalMarkMessage(box.shortCode),
    cancelLabel: context.l10n.later,
    options: PhysicalMarkMethod.values
        .map(
          (value) => IosActionSheetOption(
            label: value.label(context),
            value: value,
            icon: _methodIcon(value),
          ),
        )
        .toList(growable: false),
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
