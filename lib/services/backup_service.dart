import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/app_repository.dart';
import '../models/box_record.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

class PreparedBackup {
  const PreparedBackup({
    required this.snapshot,
    required this.missingPhotoCount,
    required this.importedPhotoPaths,
  });

  final AppSnapshot snapshot;
  final int missingPhotoCount;
  final List<String> importedPhotoPaths;
}

class BackupService {
  BackupService({SupportDirectoryProvider? supportDirectory, Uuid? uuid})
    : _supportDirectory =
          supportDirectory ?? (() => getApplicationSupportDirectory()),
      _uuid = uuid ?? const Uuid();

  static const String format = 'moving-box-backup';
  static const int formatVersion = 1;

  final SupportDirectoryProvider _supportDirectory;
  final Uuid _uuid;

  Future<Uint8List> createPackage(AppSnapshot snapshot) async {
    final data = _deepMutableMap(snapshot.toJson());
    final boxJson = (data['boxes'] as List).cast<Map<String, Object?>>();
    final archive = Archive();
    final fileManifest = <Map<String, Object?>>[];
    var missingPhotoCount = 0;

    for (var boxIndex = 0; boxIndex < snapshot.boxes.length; boxIndex++) {
      final box = snapshot.boxes[boxIndex];
      final packagedPaths = <String>[];
      for (
        var photoIndex = 0;
        photoIndex < box.photoPaths.length;
        photoIndex++
      ) {
        final file = File(box.photoPaths[photoIndex]);
        if (!await file.exists()) {
          missingPhotoCount++;
          continue;
        }
        final bytes = await file.readAsBytes();
        final path =
            'photos/${box.id}-${photoIndex + 1}${_safeExtension(file.path)}';
        packagedPaths.add(path);
        archive.add(ArchiveFile.bytes(path, bytes));
        fileManifest.add(_manifestEntry(path, bytes));
      }
      boxJson[boxIndex]['photoPaths'] = packagedPaths;
    }

    final dataBytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
    archive.add(ArchiveFile.bytes('data.json', dataBytes));
    fileManifest.insert(0, _manifestEntry('data.json', dataBytes));
    final manifest = <String, Object?>{
      'format': format,
      'formatVersion': formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'dataFile': 'data.json',
      'missingPhotoCount': missingPhotoCount,
      'files': fileManifest,
    };
    archive.add(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );
    return ZipEncoder().encodeBytes(archive);
  }

  Future<PreparedBackup> prepareImport(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entries = <String, ArchiveFile>{};
    var totalBytes = 0;
    for (final entry in archive) {
      if (!entry.isFile || !_isSafeArchivePath(entry.name)) continue;
      if (entries.containsKey(entry.name)) {
        throw const FormatException('Duplicate backup entry');
      }
      totalBytes += entry.size;
      if (totalBytes > 2 * 1024 * 1024 * 1024) {
        throw const FormatException('Backup is too large');
      }
      entries[entry.name] = entry;
    }

    final manifestEntry = entries['manifest.json'];
    if (manifestEntry == null) throw const FormatException('Missing manifest');
    final manifest = _decodeMap(manifestEntry.readBytes());
    if (manifest['format'] != format ||
        manifest['formatVersion'] != formatVersion ||
        manifest['dataFile'] != 'data.json') {
      throw const FormatException('Unsupported backup package');
    }

    final verifiedPaths = <String>{};
    final files = manifest['files'];
    if (files is! List) throw const FormatException('Invalid manifest files');
    for (final raw in files) {
      if (raw is! Map) throw const FormatException('Invalid file manifest');
      final item = raw.cast<String, Object?>();
      final path = item['path'];
      final expectedHash = item['sha256'];
      final expectedBytes = (item['bytes'] as num?)?.toInt();
      if (path is! String ||
          expectedHash is! String ||
          expectedBytes == null ||
          !_isSafeArchivePath(path) ||
          !verifiedPaths.add(path)) {
        throw const FormatException('Invalid file manifest');
      }
      final entry = entries[path];
      final content = entry?.readBytes();
      if (content == null ||
          content.length != expectedBytes ||
          sha256.convert(content).toString() != expectedHash) {
        throw const FormatException('Backup checksum mismatch');
      }
    }

    final dataBytes = entries['data.json']?.readBytes();
    if (dataBytes == null || !verifiedPaths.contains('data.json')) {
      throw const FormatException('Missing backup data');
    }
    final packagedSnapshot = AppSnapshot.fromBytes(dataBytes);
    final photoDirectory = Directory(
      '${(await _supportDirectory()).path}/moving_box/photos',
    );
    await photoDirectory.create(recursive: true);
    final importedPaths = <String>[];
    var missingPhotoCount =
        (manifest['missingPhotoCount'] as num?)?.toInt() ?? 0;
    try {
      final restoredBoxes = <BoxRecord>[];
      for (final box in packagedSnapshot.boxes) {
        final localPaths = <String>[];
        for (final packagePath in box.photoPaths) {
          final entry = entries[packagePath];
          final content = entry?.readBytes();
          if (!packagePath.startsWith('photos/') ||
              content == null ||
              !verifiedPaths.contains(packagePath)) {
            missingPhotoCount++;
            continue;
          }
          final target = File(
            '${photoDirectory.path}/${_uuid.v4()}${_safeExtension(packagePath)}',
          );
          await target.writeAsBytes(content, flush: true);
          importedPaths.add(target.path);
          localPaths.add(target.path);
        }
        restoredBoxes.add(box.copyWith(photoPaths: localPaths));
      }
      return PreparedBackup(
        snapshot: AppSnapshot(
          projects: packagedSnapshot.projects,
          boxes: restoredBoxes,
          entryBatches: packagedSnapshot.entryBatches,
          hasSeededExample: packagedSnapshot.hasSeededExample,
        ),
        missingPhotoCount: missingPhotoCount,
        importedPhotoPaths: importedPaths,
      );
    } catch (_) {
      await deleteManagedPhotos(importedPaths);
      rethrow;
    }
  }

  Future<void> deleteManagedPhotos(Iterable<String> paths) async {
    final managedRoot =
        '${(await _supportDirectory()).path}/moving_box/photos/';
    for (final path in paths.toSet()) {
      if (!path.startsWith(managedRoot)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Cleanup is best-effort and must not make a completed restore fail.
      }
    }
  }
}

Map<String, Object?> _manifestEntry(String path, List<int> bytes) => {
  'path': path,
  'bytes': bytes.length,
  'sha256': sha256.convert(bytes).toString(),
};

Map<String, Object?> _decodeMap(List<int>? bytes) {
  if (bytes == null) throw const FormatException('Unreadable backup entry');
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map) throw const FormatException('Invalid backup entry');
  return decoded.cast<String, Object?>();
}

Map<String, Object?> _deepMutableMap(Map<String, Object?> value) {
  final decoded = jsonDecode(jsonEncode(value));
  return (decoded as Map).cast<String, Object?>();
}

bool _isSafeArchivePath(String path) {
  if (path.isEmpty || path.startsWith('/') || path.startsWith(r'\')) {
    return false;
  }
  return !path.split(RegExp(r'[/\\]')).any((segment) => segment == '..');
}

String _safeExtension(String path) {
  final slash = path.lastIndexOf('/');
  final dot = path.lastIndexOf('.');
  if (dot <= slash || path.length - dot > 6) return '.jpg';
  final candidate = path.substring(dot).toLowerCase();
  return RegExp(r'^\.[a-z0-9]+$').hasMatch(candidate) ? candidate : '.jpg';
}
