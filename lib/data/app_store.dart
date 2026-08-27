import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/box_record.dart';
import '../models/entry_batch.dart';
import '../models/moving_project.dart';
import '../services/backup_service.dart';
import 'app_repository.dart';

class SampleSeed {
  const SampleSeed({
    required this.projectName,
    required this.origin,
    required this.destination,
    required this.memo,
  });

  final String projectName;
  final String origin;
  final String destination;
  final String memo;
}

class ProjectStats {
  const ProjectStats({
    required this.total,
    required this.pendingMarks,
    required this.packed,
    required this.loaded,
    required this.arrived,
    required this.unpacked,
    required this.suspectedMissing,
    required this.waitingToLoad,
    required this.notArrived,
    required this.notUnpacked,
  });

  final int total;
  final int pendingMarks;
  final int packed;
  final int loaded;
  final int arrived;
  final int unpacked;
  final int suspectedMissing;
  final int waitingToLoad;
  final int notArrived;
  final int notUnpacked;
}

class DuplicateBoxCodeException implements Exception {}

class AppStore extends ChangeNotifier {
  AppStore({
    required AppRepository repository,
    Uuid? uuid,
    BackupService? backupService,
    String initialLanguageCode = 'en',
  }) : _repository = repository,
       _uuid = uuid ?? const Uuid(),
       _backupService = backupService ?? BackupService(),
       _languageCode = ValueNotifier(
         initialLanguageCode.toLowerCase().startsWith('zh') ? 'zh' : 'en',
       );

  final AppRepository _repository;
  final Uuid _uuid;
  final BackupService _backupService;
  final ValueNotifier<String> _languageCode;

  List<MovingProject> _projects = [];
  List<BoxRecord> _boxes = [];
  List<EntryBatch> _entryBatches = [];
  bool _hasSeededExample = false;
  bool _hasCompletedOnboarding = false;
  bool _isReady = false;
  Object? _initializationError;

  bool get isReady => _isReady;
  Object? get initializationError => _initializationError;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<MovingProject> get activeProjects =>
      _projects.where((project) => !project.isArchived).toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<MovingProject> get archivedProjects =>
      _projects.where((project) => project.isArchived).toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<MovingProject> get allProjects => List.unmodifiable(_projects);
  List<BoxRecord> get allBoxes => List.unmodifiable(_boxes);
  List<EntryBatch> get allEntryBatches => List.unmodifiable(_entryBatches);
  String get languageCode => _languageCode.value;
  ValueListenable<String> get languageCodeListenable => _languageCode;

  Future<void> initialize(SampleSeed seed) async {
    _isReady = false;
    _initializationError = null;
    notifyListeners();
    try {
      String? savedLanguageCode;
      try {
        savedLanguageCode = await _repository.loadLanguageCode();
      } catch (_) {
        // A preference read must not prevent the local moving data from loading.
      }
      if (savedLanguageCode == 'zh' || savedLanguageCode == 'en') {
        _languageCode.value = savedLanguageCode!;
      }
      try {
        _hasCompletedOnboarding = await _repository
            .loadHasCompletedOnboarding();
      } catch (_) {
        // A preference read must not prevent the local moving data from loading.
      }
      final loaded = await _repository.load();
      if (loaded != null) {
        _projects = loaded.projects.toList();
        _boxes = loaded.boxes.toList();
        _entryBatches = loaded.entryBatches
            .where((batch) => batch.hasBoxes && !batch.isFinished)
            .toList();
        _hasSeededExample = loaded.hasSeededExample;
      }
      if (!_hasSeededExample) {
        await _seedExample(seed);
      }
      _isReady = true;
    } catch (error) {
      _initializationError = error;
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String languageCode) async {
    if (languageCode != 'zh' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    if (_languageCode.value == languageCode) return;
    final previous = _languageCode.value;
    _languageCode.value = languageCode;
    try {
      await _repository.saveLanguageCode(languageCode);
    } catch (_) {
      _languageCode.value = previous;
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    if (_hasCompletedOnboarding) return;
    await _repository.saveHasCompletedOnboarding(true);
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> _seedExample(SampleSeed seed) async {
    final now = DateTime.now();
    final project = MovingProject(
      id: _uuid.v4(),
      name: seed.projectName,
      origin: seed.origin,
      destination: seed.destination,
      boxPrefix: 'C',
      nextSequence: 2,
      createdAt: now,
      updatedAt: now,
    );
    final box = BoxRecord(
      id: _uuid.v4(),
      projectId: project.id,
      shortCode: project.codeFor(1),
      destinationRoom: seed.destination,
      memo: seed.memo,
      moveStatus: MoveStatus.packed,
      createdAt: now,
      updatedAt: now,
    );
    _projects = [project];
    _boxes = [box];
    _hasSeededExample = true;
    await _persist();
  }

  MovingProject projectById(String id) =>
      _projects.firstWhere((project) => project.id == id);

  BoxRecord? boxById(String id) {
    for (final box in _boxes) {
      if (box.id == id) return box;
    }
    return null;
  }

  EntryBatch? entryBatchById(String id) {
    for (final batch in _entryBatches) {
      if (batch.id == id) return batch;
    }
    return null;
  }

  EntryBatch? activeEntryBatchForProject(String projectId) {
    final batches =
        _entryBatches
            .where(
              (batch) =>
                  batch.projectId == projectId &&
                  batch.hasBoxes &&
                  !batch.isFinished,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return batches.firstOrNull;
  }

  List<BoxRecord> boxesForProject(String projectId, {String query = ''}) {
    final result = _boxes
        .where((box) => box.projectId == projectId && box.matches(query))
        .toList(growable: false);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<BoxRecord> searchAll(String query) {
    if (query.trim().isEmpty) return const [];
    final result = _boxes.where((box) => box.matches(query)).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  List<String> recentRoomsForProject(String projectId, {int limit = 6}) =>
      _recentValues(
        _recentBoxesForProject(projectId).map((box) => box.destinationRoom),
        limit,
      );

  List<String> recentLocationsForProject(String projectId, {int limit = 6}) =>
      _recentValues(
        _recentBoxesForProject(projectId).map((box) => box.currentLocation),
        limit,
      );

  List<String> recentTagsForProject(String projectId, {int limit = 8}) =>
      _recentValues(
        _recentBoxesForProject(projectId).expand((box) => box.tags),
        limit,
      );

  List<BoxRecord> _recentBoxesForProject(String projectId) =>
      _boxes.where((box) => box.projectId == projectId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  String nextCode(String projectId) {
    final project = projectById(projectId);
    return project.codeFor(project.nextSequence);
  }

  bool isCodeAvailable(String projectId, String code, {String? excludingId}) {
    final normalized = code.trim().toLowerCase();
    return !_boxes.any(
      (box) =>
          box.projectId == projectId &&
          box.id != excludingId &&
          box.shortCode.toLowerCase() == normalized,
    );
  }

  Future<MovingProject> createProject({
    required String name,
    String origin = '',
    String destination = '',
    String boxPrefix = 'C',
  }) async {
    final now = DateTime.now();
    final project = MovingProject(
      id: _uuid.v4(),
      name: name.trim(),
      origin: origin.trim(),
      destination: destination.trim(),
      boxPrefix: _normalizedPrefix(boxPrefix),
      nextSequence: 1,
      createdAt: now,
      updatedAt: now,
    );
    final previous = _projects;
    _projects = [..._projects, project];
    try {
      await _persist();
    } catch (_) {
      _projects = previous;
      rethrow;
    }
    notifyListeners();
    return project;
  }

  Future<void> updateProject(MovingProject updated) async {
    final index = _projects.indexWhere((project) => project.id == updated.id);
    if (index < 0) throw StateError('Project not found');
    final previous = _projects;
    final next = previous.toList();
    next[index] = updated.copyWith(
      name: updated.name.trim(),
      origin: updated.origin.trim(),
      destination: updated.destination.trim(),
      boxPrefix: _normalizedPrefix(updated.boxPrefix),
      updatedAt: DateTime.now(),
    );
    _projects = next;
    try {
      await _persist();
    } catch (_) {
      _projects = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<BoxRecord> createBox({
    required String projectId,
    String? shortCode,
    String title = '',
    String destinationRoom = '',
    String currentLocation = '',
    String memo = '',
    List<String> tags = const [],
    List<BoxItem> items = const [],
    List<String> photoPaths = const [],
    bool isPriority = false,
    String? entryBatchId,
  }) async {
    final projectIndex = _projects.indexWhere(
      (project) => project.id == projectId,
    );
    if (projectIndex < 0) throw StateError('Project not found');
    final project = _projects[projectIndex];
    final generatedCode = project.codeFor(project.nextSequence);
    final code = (shortCode ?? generatedCode).trim().toUpperCase();
    if (!isCodeAvailable(projectId, code)) throw DuplicateBoxCodeException();
    final now = DateTime.now();
    final box = BoxRecord(
      id: _uuid.v4(),
      projectId: projectId,
      shortCode: code,
      title: title.trim(),
      destinationRoom: destinationRoom.trim(),
      currentLocation: currentLocation.trim(),
      memo: memo.trim(),
      tags: _cleanList(tags),
      items: _cleanItems(items),
      photoPaths: photoPaths,
      isPriority: isPriority,
      createdAt: now,
      updatedAt: now,
    );
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final oldBatches = _entryBatches;
    final nextProjects = oldProjects.toList();
    nextProjects[projectIndex] = project.copyWith(
      nextSequence: project.nextSequence + 1,
      updatedAt: now,
    );
    _projects = nextProjects;
    _boxes = [...oldBoxes, box];
    if (entryBatchId != null) {
      final batchIndex = _entryBatches.indexWhere(
        (batch) => batch.id == entryBatchId,
      );
      if (batchIndex < 0 || _entryBatches[batchIndex].projectId != projectId) {
        _projects = oldProjects;
        _boxes = oldBoxes;
        throw StateError('Entry batch not found');
      }
      final nextBatches = _entryBatches.toList();
      final batch = nextBatches[batchIndex];
      nextBatches[batchIndex] = batch.copyWith(
        boxIds: [...batch.boxIds, box.id],
        updatedAt: now,
      );
      _entryBatches = nextBatches;
    }
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      _entryBatches = oldBatches;
      rethrow;
    }
    notifyListeners();
    return box;
  }

  Future<void> updateBox(
    BoxRecord updated, {
    StatusChangeSource statusSource = StatusChangeSource.manual,
  }) async {
    final index = _boxes.indexWhere((box) => box.id == updated.id);
    if (index < 0) throw StateError('Box not found');
    final code = updated.shortCode.trim().toUpperCase();
    if (!isCodeAvailable(updated.projectId, code, excludingId: updated.id)) {
      throw DuplicateBoxCodeException();
    }
    final previous = _boxes;
    final next = previous.toList();
    final current = previous[index];
    final statusHistory = current.statusHistory.toList();
    if (current.moveStatus != updated.moveStatus) {
      statusHistory.add(
        StatusHistoryEntry(
          id: _uuid.v4(),
          from: current.moveStatus,
          to: updated.moveStatus,
          source: statusSource,
          changedAt: DateTime.now(),
        ),
      );
    }
    next[index] = updated.copyWith(
      shortCode: code,
      title: updated.title.trim(),
      destinationRoom: updated.destinationRoom.trim(),
      currentLocation: updated.currentLocation.trim(),
      memo: updated.memo.trim(),
      tags: _cleanList(updated.tags),
      items: _cleanItems(updated.items),
      statusHistory: statusHistory,
      updatedAt: DateTime.now(),
    );
    _boxes = next;
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> undoLastStatusChange(String boxId) async {
    final index = _boxes.indexWhere((box) => box.id == boxId);
    if (index < 0) throw StateError('Box not found');
    final box = _boxes[index];
    if (box.statusHistory.isEmpty) return;
    final last = box.statusHistory.last;
    final previous = _boxes;
    final next = previous.toList();
    next[index] = box.copyWith(
      moveStatus: last.from,
      statusHistory: box.statusHistory.sublist(0, box.statusHistory.length - 1),
      updatedAt: DateTime.now(),
    );
    _boxes = next;
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<EntryBatch> createEntryBatch({
    required String projectId,
    required EntryBatchSource source,
  }) async {
    projectById(projectId);
    final now = DateTime.now();
    final batch = EntryBatch(
      id: _uuid.v4(),
      projectId: projectId,
      source: source,
      boxIds: const [],
      nextIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final previous = _entryBatches;
    _entryBatches = [..._entryBatches, batch];
    try {
      await _persist();
    } catch (_) {
      _entryBatches = previous;
      rethrow;
    }
    notifyListeners();
    return batch;
  }

  Future<void> advanceEntryBatch(String id, int nextIndex) async {
    final index = _entryBatches.indexWhere((batch) => batch.id == id);
    if (index < 0) throw StateError('Entry batch not found');
    final previous = _entryBatches;
    final next = previous.toList();
    final batch = next[index];
    next[index] = batch.copyWith(
      nextIndex: nextIndex.clamp(0, batch.boxIds.length),
      updatedAt: DateTime.now(),
    );
    _entryBatches = next;
    try {
      await _persist();
    } catch (_) {
      _entryBatches = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> applyEntryBatchDetails(
    String id, {
    required int fromIndex,
    String destinationRoom = '',
    List<String> tags = const [],
  }) async {
    final batch = entryBatchById(id);
    if (batch == null) throw StateError('Entry batch not found');
    final ids = batch.boxIds
        .skip(fromIndex.clamp(0, batch.boxIds.length))
        .toSet();
    final normalizedRoom = destinationRoom.trim();
    final normalizedTags = _cleanList(tags);
    final previous = _boxes;
    final now = DateTime.now();
    _boxes = _boxes.map((box) {
      if (!ids.contains(box.id)) return box;
      return box.copyWith(
        destinationRoom: normalizedRoom.isEmpty
            ? box.destinationRoom
            : normalizedRoom,
        tags: _cleanList([...box.tags, ...normalizedTags]),
        updatedAt: now,
      );
    }).toList();
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> finishEntryBatch(String id) async {
    final previous = _entryBatches;
    _entryBatches = _entryBatches.where((batch) => batch.id != id).toList();
    try {
      await _persist();
    } catch (_) {
      _entryBatches = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> discardEmptyEntryBatch(String id) async {
    final batch = entryBatchById(id);
    if (batch == null || batch.hasBoxes) return;
    await finishEntryBatch(id);
  }

  Future<void> deleteBox(String id) async {
    final previous = _boxes;
    final previousBatches = _entryBatches;
    _boxes = _boxes.where((box) => box.id != id).toList();
    _entryBatches = _entryBatches
        .map((batch) {
          final removedIndex = batch.boxIds.indexOf(id);
          if (removedIndex < 0) return batch;
          final nextIds = batch.boxIds.where((boxId) => boxId != id).toList();
          final nextIndex = removedIndex < batch.nextIndex
              ? batch.nextIndex - 1
              : batch.nextIndex;
          return batch.copyWith(
            boxIds: nextIds,
            nextIndex: nextIndex.clamp(0, nextIds.length),
            updatedAt: DateTime.now(),
          );
        })
        .where((batch) => batch.hasBoxes)
        .toList();
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
      _entryBatches = previousBatches;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> setProjectArchived(String id, bool archived) async {
    final project = projectById(id);
    await updateProject(
      project.copyWith(archivedAt: archived ? DateTime.now() : null),
    );
  }

  Future<void> deleteProject(String id) async {
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final oldBatches = _entryBatches;
    _projects = _projects.where((project) => project.id != id).toList();
    _boxes = _boxes.where((box) => box.projectId != id).toList();
    _entryBatches = _entryBatches
        .where((batch) => batch.projectId != id)
        .toList();
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      _entryBatches = oldBatches;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> confirmPhysicalMark(
    String boxId,
    PhysicalMarkMethod method,
  ) async {
    final box = boxById(boxId);
    if (box == null) throw StateError('Box not found');
    await updateBox(
      box.copyWith(
        physicalMarkStatus: PhysicalMarkStatus.confirmed,
        physicalMarkMethod: method,
        physicalMarkedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markLabelExported(Iterable<String> boxIds) async {
    final ids = boxIds.toSet();
    final now = DateTime.now();
    final previous = _boxes;
    _boxes = _boxes
        .map(
          (box) => ids.contains(box.id)
              ? box.copyWith(labelExportedAt: now, updatedAt: now)
              : box,
        )
        .toList();
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
      rethrow;
    }
    notifyListeners();
  }

  ProjectStats statsFor(String projectId) {
    final boxes = boxesForProject(projectId);
    int atLeast(MoveStatus status) =>
        boxes.where((box) => box.moveStatus.index >= status.index).length;
    return ProjectStats(
      total: boxes.length,
      pendingMarks: boxes
          .where((box) => box.physicalMarkStatus == PhysicalMarkStatus.pending)
          .length,
      packed: atLeast(MoveStatus.packed),
      loaded: atLeast(MoveStatus.loaded),
      arrived: atLeast(MoveStatus.arrived),
      unpacked: atLeast(MoveStatus.unpacked),
      suspectedMissing: boxes
          .where((box) => box.issues.contains(BoxIssue.suspectedMissing))
          .length,
      waitingToLoad: boxes
          .where((box) => box.moveStatus.index < MoveStatus.loaded.index)
          .length,
      notArrived: boxes
          .where((box) => box.moveStatus.index < MoveStatus.arrived.index)
          .length,
      notUnpacked: boxes
          .where((box) => box.moveStatus.index < MoveStatus.unpacked.index)
          .length,
    );
  }

  Uint8List exportBackup() => _snapshot().toBytes();

  Future<Uint8List> exportBackupPackage() =>
      _backupService.createPackage(_snapshot());

  Future<void> importBackup(List<int> bytes) async {
    final imported = AppSnapshot.fromBytes(bytes);
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final oldBatches = _entryBatches;
    final oldSeeded = _hasSeededExample;
    _projects = imported.projects.toList();
    _boxes = imported.boxes.toList();
    _entryBatches = imported.entryBatches.toList();
    _hasSeededExample = imported.hasSeededExample;
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      _entryBatches = oldBatches;
      _hasSeededExample = oldSeeded;
      rethrow;
    }
    notifyListeners();
  }

  Future<int> importBackupPackage(List<int> bytes) async {
    final prepared = await _backupService.prepareImport(bytes);
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final oldBatches = _entryBatches;
    final oldSeeded = _hasSeededExample;
    _projects = prepared.snapshot.projects.toList();
    _boxes = prepared.snapshot.boxes.toList();
    _entryBatches = prepared.snapshot.entryBatches.toList();
    _hasSeededExample = prepared.snapshot.hasSeededExample;
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      _entryBatches = oldBatches;
      _hasSeededExample = oldSeeded;
      await _backupService.deleteManagedPhotos(prepared.importedPhotoPaths);
      rethrow;
    }
    final retained = prepared.importedPhotoPaths.toSet();
    await _backupService.deleteManagedPhotos(
      oldBoxes
          .expand((box) => box.photoPaths)
          .where((path) => !retained.contains(path)),
    );
    notifyListeners();
    return prepared.missingPhotoCount;
  }

  Future<void> _persist() => _repository.save(_snapshot());

  AppSnapshot _snapshot() => AppSnapshot(
    projects: _projects,
    boxes: _boxes,
    entryBatches: _entryBatches,
    hasSeededExample: _hasSeededExample,
  );

  @override
  void dispose() {
    _languageCode.dispose();
    super.dispose();
  }
}

String _normalizedPrefix(String value) {
  final normalized = value.trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]'),
    '',
  );
  return normalized.isEmpty
      ? 'C'
      : normalized.substring(0, normalized.length.clamp(1, 6));
}

List<String> _cleanList(Iterable<String> values) {
  final seen = <String>{};
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
      .toList(growable: false);
}

List<BoxItem> _cleanItems(Iterable<BoxItem> items) => items
    .map(
      (item) => item.copyWith(name: item.name.trim(), note: item.note.trim()),
    )
    .where((item) => item.name.isNotEmpty)
    .toList(growable: false);

List<String> _recentValues(Iterable<String> values, int limit) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in values) {
    final value = raw.trim();
    if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
    result.add(value);
    if (result.length >= limit) break;
  }
  return result;
}
