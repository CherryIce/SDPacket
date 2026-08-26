import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving_project.dart';

Future<MovingProject?> showProjectFormDialog(
  BuildContext context, {
  MovingProject? project,
}) {
  return showDialog<MovingProject>(
    context: context,
    builder: (_) => ProjectFormDialog(project: project),
  );
}

class ProjectFormDialog extends StatefulWidget {
  const ProjectFormDialog({super.key, this.project});

  final MovingProject? project;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _destination;
  late final TextEditingController _prefix;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _name = TextEditingController(text: project?.name ?? '');
    _origin = TextEditingController(text: project?.origin ?? '');
    _destination = TextEditingController(text: project?.destination ?? '');
    _prefix = TextEditingController(text: project?.boxPrefix ?? 'C');
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _destination.dispose();
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = StoreScope.of(context);
    try {
      final existing = widget.project;
      final MovingProject saved;
      if (existing == null) {
        saved = await store.createProject(
          name: _name.text,
          origin: _origin.text,
          destination: _destination.text,
          boxPrefix: _prefix.text,
        );
      } else {
        saved = existing.copyWith(
          name: _name.text,
          origin: _origin.text,
          destination: _destination.text,
          boxPrefix: _prefix.text,
        );
        await store.updateProject(saved);
      }
      if (mounted) Navigator.pop(context, saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    return AlertDialog(
      title: Text(
        isEditing ? context.l10n.editProject : context.l10n.newProject,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.projectName,
                ),
                validator: (value) => (value ?? '').trim().isEmpty ? '' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _origin,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: context.l10n.origin),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _destination,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.destination,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prefix,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: context.l10n.boxPrefix),
                validator: (value) => (value ?? '').trim().isEmpty ? '' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? context.l10n.save : context.l10n.create),
        ),
      ],
    );
  }
}
