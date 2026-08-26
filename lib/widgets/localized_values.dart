import 'package:flutter/widgets.dart';

import '../app.dart';
import '../models/box_record.dart';

extension LocalizedMoveStatus on MoveStatus {
  String label(BuildContext context) => switch (this) {
    MoveStatus.draft => context.l10n.draft,
    MoveStatus.packed => context.l10n.packed,
    MoveStatus.loaded => context.l10n.loaded,
    MoveStatus.arrived => context.l10n.arrived,
    MoveStatus.unpacked => context.l10n.unpacked,
  };
}

extension LocalizedMarkMethod on PhysicalMarkMethod {
  String label(BuildContext context) => switch (this) {
    PhysicalMarkMethod.qrLabel => context.l10n.qrLabel,
    PhysicalMarkMethod.handwritten => context.l10n.handwritten,
    PhysicalMarkMethod.stickyNote => context.l10n.stickyNote,
    PhysicalMarkMethod.other => context.l10n.other,
  };
}

extension LocalizedIssue on BoxIssue {
  String label(BuildContext context) => switch (this) {
    BoxIssue.suspectedMissing => context.l10n.suspectedMissing,
    BoxIssue.damagedBox => context.l10n.damagedBox,
    BoxIssue.damagedContents => context.l10n.damagedContents,
  };
}
