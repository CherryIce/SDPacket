import 'package:flutter/material.dart';

import '../app.dart';
import '../data/app_store.dart';
import '../models/moving_project.dart';
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
    final action = await showModalBottomSheet<_HomeAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => _HomeMoreSheet(
        onSelected: (action) => Navigator.pop(sheetContext, action),
        onCancel: () => Navigator.pop(sheetContext),
      ),
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
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(
          context.l10n.projects,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: projects.isEmpty
          ? _EmptyProjects(onCreate: () => _createProject(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: projects.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    context.l10n.activeProjects,
                    key: const Key('home-active-projects-label'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return _ProjectCard(project: projects[index - 1], store: store);
              },
            ),
      bottomNavigationBar: projects.isEmpty
          ? null
          : _CreateProjectBar(onCreate: () => _createProject(context)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (project.origin.isNotEmpty ||
                            project.destination.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '${project.origin}${project.origin.isNotEmpty && project.destination.isNotEmpty ? ' → ' : ''}${project.destination}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                context.l10n.boxCount(stats.total),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              _ProjectMetrics(stats: stats),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectMetrics extends StatelessWidget {
  const _ProjectMetrics({required this.stats});

  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final arrived = _StatusMetric(
      icon: Icons.task_alt,
      label: '${context.l10n.arrived} ${stats.arrived}/${stats.total}',
      color: colorScheme.primary,
    );
    final pending = stats.pendingMarks == 0
        ? null
        : _StatusMetric(
            icon: Icons.label_outline,
            label: '${context.l10n.pendingPhysicalMark} ${stats.pendingMarks}',
            color: colorScheme.error,
          );
    if (pending == null) return arrived;

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackMetrics = constraints.maxWidth < 320 || textScale > 1.15;
        if (stackMetrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              arrived,
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              pending,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: arrived),
              VerticalDivider(
                width: 28,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              Expanded(child: pending),
            ],
          ),
        );
      },
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateProjectBar extends StatelessWidget {
  const _CreateProjectBar({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: SizedBox(
          height: 54,
          child: FilledButton.icon(
            key: const Key('home-create-project'),
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.add, size: 27),
            label: Text(context.l10n.newProject),
          ),
        ),
      ),
    );
  }
}

class _HomeMoreSheet extends StatelessWidget {
  const _HomeMoreSheet({required this.onSelected, required this.onCancel});

  final ValueChanged<_HomeAction> onSelected;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          key: const Key('home-more-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.moreActions,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HomeMoreActionTile(
                      key: const Key('home-more-archived'),
                      icon: Icons.archive_outlined,
                      label: context.l10n.archivedProjects,
                      onTap: () => onSelected(_HomeAction.archived),
                    ),
                    Divider(
                      height: 1,
                      indent: 72,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    _HomeMoreActionTile(
                      key: const Key('home-more-settings'),
                      icon: Icons.settings_outlined,
                      label: context.l10n.settings,
                      onTap: () => onSelected(_HomeAction.settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: TextButton(
                  key: const Key('home-more-cancel'),
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(context.l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMoreActionTile extends StatelessWidget {
  const _HomeMoreActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 22,
        color: colorScheme.onSurfaceVariant,
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
