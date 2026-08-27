import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/box_record.dart';
import '../models/entry_batch.dart';
import '../models/moving_project.dart';

class AppSnapshot {
  const AppSnapshot({
    required this.projects,
    required this.boxes,
    this.entryBatches = const [],
    required this.hasSeededExample,
  });

  static const int currentSchemaVersion = 2;

  final List<MovingProject> projects;
  final List<BoxRecord> boxes;
  final List<EntryBatch> entryBatches;
  final bool hasSeededExample;

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'hasSeededExample': hasSeededExample,
    'projects': projects.map((project) => project.toJson()).toList(),
    'boxes': boxes.map((box) => box.toJson()).toList(),
    'entryBatches': entryBatches.map((batch) => batch.toJson()).toList(),
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
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt();
    if (schemaVersion != 1 && schemaVersion != currentSchemaVersion) {
      throw const FormatException('Unsupported schema version');
    }
    final projects = _mapList(
      json['projects'],
    ).map(MovingProject.fromJson).toList(growable: false);
    final boxes = _mapList(
      json['boxes'],
    ).map(BoxRecord.fromJson).toList(growable: false);
    final entryBatches = schemaVersion == 1
        ? <EntryBatch>[]
        : _mapList(
            json['entryBatches'],
          ).map(EntryBatch.fromJson).toList(growable: false);
    _validate(projects, boxes, entryBatches);
    return AppSnapshot(
      projects: projects,
      boxes: boxes,
      entryBatches: entryBatches,
      hasSeededExample: json['hasSeededExample'] as bool? ?? true,
    );
  }

  static void _validate(
    List<MovingProject> projects,
    List<BoxRecord> boxes,
    List<EntryBatch> entryBatches,
  ) {
    final projectIds = <String>{};
    for (final project in projects) {
      if (!projectIds.add(project.id) || project.nextSequence < 1) {
        throw const FormatException('Invalid project identity or sequence');
      }
    }
    final batches = <String>{};
    final batchedBoxIds = <String>{};
    for (final batch in entryBatches) {
      if (!batches.add(batch.id) ||
          !projectIds.contains(batch.projectId) ||
          batch.nextIndex < 0 ||
          batch.nextIndex > batch.boxIds.length) {
        throw const FormatException('Invalid entry batch');
      }
      final uniqueBoxes = <String>{};
      for (final id in batch.boxIds) {
        final box = boxes.where((candidate) => candidate.id == id).firstOrNull;
        if (!uniqueBoxes.add(id) ||
            !batchedBoxIds.add(id) ||
            box == null ||
            box.projectId != batch.projectId) {
          throw const FormatException('Invalid entry batch box');
        }
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

  Future<String?> loadLanguageCode();

  Future<void> saveLanguageCode(String languageCode);

  Future<bool> loadHasCompletedOnboarding();

  Future<void> saveHasCompletedOnboarding(bool value);
}

class FileAppRepository implements AppRepository {
  File? _dataFile;
  File? _preferencesFile;

  Future<File> _resolveDataFile() async {
    final cached = _dataFile;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/moving_box');
    await directory.create(recursive: true);
    return _dataFile = File('${directory.path}/app_data.json');
  }

  Future<File> _resolvePreferencesFile() async {
    final cached = _preferencesFile;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/moving_box');
    await directory.create(recursive: true);
    return _preferencesFile = File('${directory.path}/preferences.json');
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

  @override
  Future<String?> loadLanguageCode() async {
    final languageCode = (await _readPreferences())['languageCode'];
    return languageCode is String ? languageCode : null;
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    await _updatePreferences({'languageCode': languageCode});
  }

  @override
  Future<bool> loadHasCompletedOnboarding() async =>
      (await _readPreferences())['hasCompletedOnboarding'] == true;

  @override
  Future<void> saveHasCompletedOnboarding(bool value) async {
    await _updatePreferences({'hasCompletedOnboarding': value});
  }

  Future<Map<String, Object?>> _readPreferences() async {
    final file = await _resolvePreferencesFile();
    if (!await file.exists()) return const {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const {};
      return decoded.cast<String, Object?>();
    } on FormatException {
      return const {};
    } on FileSystemException {
      return const {};
    }
  }

  Future<void> _updatePreferences(Map<String, Object?> values) async {
    final file = await _resolvePreferencesFile();
    final preferences = {...await _readPreferences(), ...values};
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(preferences), flush: true);
    await temporary.rename(file.path);
  }
}

class InMemoryAppRepository implements AppRepository {
  InMemoryAppRepository([
    this.snapshot,
    this.languageCode,
    this.hasCompletedOnboarding = false,
  ]);

  InMemoryAppRepository.onboarded([this.snapshot, this.languageCode])
    : hasCompletedOnboarding = true;

  AppSnapshot? snapshot;
  String? languageCode;
  bool hasCompletedOnboarding;

  @override
  Future<AppSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    this.snapshot = AppSnapshot.fromBytes(snapshot.toBytes());
  }

  @override
  Future<String?> loadLanguageCode() async => languageCode;

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }

  @override
  Future<bool> loadHasCompletedOnboarding() async => hasCompletedOnboarding;

  @override
  Future<void> saveHasCompletedOnboarding(bool value) async {
    hasCompletedOnboarding = value;
  }
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List) throw const FormatException('Invalid object list');
  return value
      .map((item) => (item as Map).cast<String, Object?>())
      .toList(growable: false);
}
