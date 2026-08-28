import 'package:flutter/material.dart';

import '../app.dart';
import '../models/box_record.dart';
import '../widgets/localized_values.dart';
import 'box_editor_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final results = store.searchAll(_query.text);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.globalSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.l10n.searchAllHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _query.text.trim().isEmpty
                ? const SizedBox.shrink()
                : results.isEmpty
                ? Center(child: Text(context.l10n.noResults))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _SearchResult(
                      box: results[index],
                      projectName: store
                          .projectById(results[index].projectId)
                          .name,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({required this.box, required this.projectName});

  final BoxRecord box;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text('${box.shortCode} · ${box.moveStatus.label(context)}'),
        subtitle: Text(
          [
            projectName,
            box.destinationRoom,
            box.memo,
          ].where((value) => value.isNotEmpty).join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<String>(
            builder: (_) => BoxEditorScreen(boxId: box.id),
          ),
        ),
      ),
    );
  }
}
