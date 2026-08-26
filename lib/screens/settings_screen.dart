import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _shareBackup() async {
    setState(() => _busy = true);
    try {
      final bytes = StoreScope.of(context).exportBackup();
      final renderBox = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/json')],
          fileNameOverrides: ['moving-box-backup.json'],
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final store = StoreScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.restoreBackup),
        content: Text(context.l10n.restoreWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) throw const FormatException('Unreadable backup');
      await store.importBackup(bytes);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.restoreSuccess)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidBackup)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInfo(String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(context.l10n.backup),
                  trailing: const Icon(Icons.ios_share),
                  enabled: !_busy,
                  onTap: _shareBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(context.l10n.restoreBackup),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(context.l10n.privacy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showInfo(context.l10n.privacy, context.l10n.privacyBody),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_iphone_outlined),
                  title: Text(context.l10n.platformSupport),
                  subtitle: Text(context.l10n.platformSupportBody),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(context.l10n.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showInfo(context.l10n.about, context.l10n.aboutBody),
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 22),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
