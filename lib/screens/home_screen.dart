import 'package:flutter/material.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/moving_project.dart';
import '../widgets/ios_modal.dart';
import '../widgets/project_form_dialog.dart';
import 'archived_projects_screen.dart';
import 'global_search_screen.dart';
import 'project_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createProject(BuildContext context) async {
    final project = await showProjectFormDialog(context);
    if (project != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProjectDetailScreen(projectId: project.id),
        ),
      );
    }
  }

  Future<void> _showMore(BuildContext context) async {
    final action = await showIosActionSheet<_HomeAction>(
      context: context,
      cancelLabel: context.l10n.cancel,
      options: [
        IosActionSheetOption(
          label: context.l10n.archivedProjects,
          value: _HomeAction.archived,
          icon: Icons.archive_outlined,
        ),
        IosActionSheetOption(
          label: context.l10n.settings,
          value: _HomeAction.settings,
          icon: Icons.settings_outlined,
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    final screen = switch (action) {
      _HomeAction.archived => const ArchivedProjectsScreen(),
      _HomeAction.settings => const SettingsScreen(),
    };
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.isReady) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: store.initializationError == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(context.l10n.loading),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 12),
                      Text(context.l10n.dataError),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => store.initialize(
                          SampleSeed(
                            projectName: context.l10n.sampleProjectName,
                            origin: context.l10n.sampleOrigin,
                            destination: context.l10n.sampleDestination,
                            memo: context.l10n.sampleMemo,
                          ),
                        ),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    final projects = store.activeProjects;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.projects),
        actions: [
          IconButton(
            tooltip: context.l10n.globalSearch,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const GlobalSearchScreen(),
              ),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: context.l10n.moreActions,
            onPressed: () => _showMore(context),
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: projects.isEmpty
          ? _EmptyProjects(onCreate: () => _createProject(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ProjectCard(project: projects[index], store: store),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newProject),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.store});

  final MovingProject project;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final stats = store.statsFor(project.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (project.origin.isNotEmpty ||
                  project.destination.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${project.origin}${project.origin.isNotEmpty && project.destination.isNotEmpty ? ' → ' : ''}${project.destination}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: context.l10n.boxCount(stats.total),
                  ),
                  if (stats.pendingMarks > 0)
                    _MetricChip(
                      icon: Icons.label_outline,
                      label:
                          '${context.l10n.pendingPhysicalMark} ${stats.pendingMarks}',
                      alert: true,
                    ),
                  _MetricChip(
                    icon: Icons.task_alt,
                    label:
                        '${context.l10n.arrived} ${stats.arrived}/${stats.total}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final color = alert
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(color: color), softWrap: true),
          ),
        ],
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              context.l10n.noProjects,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.noProjectsHint, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.newProject),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HomeAction { archived, settings }
