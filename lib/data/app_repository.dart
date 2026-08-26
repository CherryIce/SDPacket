import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/box_record.dart';
import '../models/moving_project.dart';

class AppSnapshot {
  const AppSnapshot({
    required this.projects,
    required this.boxes,
    required this.hasSeededExample,
  });

  static const int currentSchemaVersion = 1;

  final List<MovingProject> projects;
  final List<BoxRecord> boxes;
  final bool hasSeededExample;

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'hasSeededExample': hasSeededExample,
    'projects': projects.map((project) => project.toJson()).toList(),
    'boxes': boxes.map((box) => box.toJson()).toList(),
  };

  Uint8List toBytes() => Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(toJson())),
  );

  factory AppSnapshot.fromBytes(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('Invalid backup root');
    return AppSnapshot.fromJson(decoded.cast<String, Object?>());
  }

  factory AppSnapshot.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw const FormatException('Unsupported schema version');
    }
    final projects = _mapList(
      json['projects'],
    ).map(MovingProject.fromJson).toList(growable: false);
    final boxes = _mapList(
      json['boxes'],
    ).map(BoxRecord.fromJson).toList(growable: false);
    _validate(projects, boxes);
    return AppSnapshot(
      projects: projects,
      boxes: boxes,
      hasSeededExample: json['hasSeededExample'] as bool? ?? true,
    );
  }

  static void _validate(List<MovingProject> projects, List<BoxRecord> boxes) {
    final projectIds = <String>{};
    for (final project in projects) {
      if (!projectIds.add(project.id) || project.nextSequence < 1) {
        throw const FormatException('Invalid project identity or sequence');
      }
    }
    final boxIds = <String>{};
    final projectCodes = <String>{};
    for (final box in boxes) {
      if (!boxIds.add(box.id) || !projectIds.contains(box.projectId)) {
        throw const FormatException('Invalid box identity or project link');
      }
      final uniqueCode = '${box.projectId}\n${box.shortCode.toLowerCase()}';
      if (!projectCodes.add(uniqueCode)) {
        throw const FormatException('Duplicate box code');
      }
    }
  }
}

abstract interface class AppRepository {
  Future<AppSnapshot?> load();

  Future<void> save(AppSnapshot snapshot);
}

class FileAppRepository implements AppRepository {
  File? _dataFile;

  Future<File> _resolveDataFile() async {
    final cached = _dataFile;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/moving_box');
    await directory.create(recursive: true);
    return _dataFile = File('${directory.path}/app_data.json');
  }

  @override
  Future<AppSnapshot?> load() async {
    final file = await _resolveDataFile();
    if (!await file.exists()) return null;
    try {
      return AppSnapshot.fromBytes(await file.readAsBytes());
    } on FormatException {
      final backup = File('${file.path}.bak');
      if (!await backup.exists()) rethrow;
      return AppSnapshot.fromBytes(await backup.readAsBytes());
    }
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    final file = await _resolveDataFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsBytes(snapshot.toBytes(), flush: true);
    if (await file.exists()) await file.copy(backup.path);
    await temporary.rename(file.path);
  }
}

class InMemoryAppRepository implements AppRepository {
  InMemoryAppRepository([this.snapshot]);

  AppSnapshot? snapshot;

  @override
  Future<AppSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    this.snapshot = AppSnapshot.fromBytes(snapshot.toBytes());
  }
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List) throw const FormatException('Invalid object list');
  return value
      .map((item) => (item as Map).cast<String, Object?>())
      .toList(growable: false);
}
