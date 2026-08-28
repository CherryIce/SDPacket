import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving_project.dart';
import 'ios_modal.dart';

Future<MovingProject?> showProjectFormDialog(
  BuildContext context, {
  MovingProject? project,
}) {
  return showIosFormSheet<MovingProject>(
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

class _ProjectFormDialogState extends State<ProjectFormDialog>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _originFocus = FocusNode();
  final _destinationFocus = FocusNode();
  final _prefixFocus = FocusNode();
  final _nameAnchor = GlobalKey();
  final _originAnchor = GlobalKey();
  final _destinationAnchor = GlobalKey();
  final _prefixAnchor = GlobalKey();
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
    WidgetsBinding.instance.addObserver(this);
    for (final focusNode in _focusNodes) {
      focusNode.addListener(_scheduleFocusedFieldReveal);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final focusNode in _focusNodes) {
      focusNode.removeListener(_scheduleFocusedFieldReveal);
      focusNode.dispose();
    }
    _name.dispose();
    _origin.dispose();
    _destination.dispose();
    _prefix.dispose();
    super.dispose();
  }

  List<FocusNode> get _focusNodes => [
    _nameFocus,
    _originFocus,
    _destinationFocus,
    _prefixFocus,
  ];

  @override
  void didChangeMetrics() {
    _scheduleFocusedFieldReveal();
  }

  GlobalKey? get _focusedAnchor {
    if (_nameFocus.hasFocus) return _nameAnchor;
    if (_originFocus.hasFocus) return _originAnchor;
    if (_destinationFocus.hasFocus) return _destinationAnchor;
    if (_prefixFocus.hasFocus) return _prefixAnchor;
    return null;
  }

  void _scheduleFocusedFieldReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _focusedAnchor?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
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
    const scrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 100);
    return IosFormSheet(
      title: isEditing ? context.l10n.editProject : context.l10n.newProject,
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: _nameAnchor,
                child: TextFormField(
                  key: const Key('project-name-field'),
                  controller: _name,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.projectName,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '' : null,
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _originAnchor,
                child: TextField(
                  key: const Key('project-origin-field'),
                  controller: _origin,
                  focusNode: _originFocus,
                  textInputAction: TextInputAction.next,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.origin,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _destinationAnchor,
                child: TextField(
                  key: const Key('project-destination-field'),
                  controller: _destination,
                  focusNode: _destinationFocus,
                  textInputAction: TextInputAction.next,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.destination,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _prefixAnchor,
                child: TextFormField(
                  key: const Key('project-prefix-field'),
                  controller: _prefix,
                  focusNode: _prefixFocus,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  scrollPadding: scrollPadding,
                  decoration: iosFormFieldDecoration(
                    context,
                    label: context.l10n.boxPrefix,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '' : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IosFormDialogAction(
          label: context.l10n.cancel,
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        IosFormDialogAction(
          label: isEditing ? context.l10n.save : context.l10n.create,
          isDefaultAction: true,
          onPressed: _saving ? null : _submit,
          child: _saving ? const CupertinoActivityIndicator() : null,
        ),
      ],
    );
  }
}
