import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving_project.dart';
import 'project_detail_screen.dart';

class ArchivedProjectsScreen extends StatelessWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final projects = store.archivedProjects;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.archivedProjects)),
      body: projects.isEmpty
          ? Center(child: Text(context.l10n.noArchived))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ArchivedProjectTile(project: projects[index]),
            ),
    );
  }
}

class _ArchivedProjectTile extends StatelessWidget {
  const _ArchivedProjectTile({required this.project});

  final MovingProject project;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(child: Icon(Icons.archive_outlined)),
        title: Text(project.name),
        subtitle: Text(context.l10n.boxCount(store.statsFor(project.id).total)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () => store.setProjectArchived(project.id, false),
          child: Text(context.l10n.restore),
        ),
      ),
    );
  }
}
