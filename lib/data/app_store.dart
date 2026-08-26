import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/box_record.dart';
import '../models/moving_project.dart';
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
  });

  final int total;
  final int pendingMarks;
  final int packed;
  final int loaded;
  final int arrived;
  final int unpacked;
  final int suspectedMissing;
}

class DuplicateBoxCodeException implements Exception {}

class AppStore extends ChangeNotifier {
  AppStore({required AppRepository repository, Uuid? uuid})
    : _repository = repository,
      _uuid = uuid ?? const Uuid();

  final AppRepository _repository;
  final Uuid _uuid;

  List<MovingProject> _projects = [];
  List<BoxRecord> _boxes = [];
  bool _hasSeededExample = false;
  bool _isReady = false;
  Object? _initializationError;

  bool get isReady => _isReady;
  Object? get initializationError => _initializationError;
  List<MovingProject> get activeProjects =>
      _projects.where((project) => !project.isArchived).toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<MovingProject> get archivedProjects =>
      _projects.where((project) => project.isArchived).toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<MovingProject> get allProjects => List.unmodifiable(_projects);
  List<BoxRecord> get allBoxes => List.unmodifiable(_boxes);

  Future<void> initialize(SampleSeed seed) async {
    _isReady = false;
    _initializationError = null;
    notifyListeners();
    try {
      final loaded = await _repository.load();
      if (loaded != null) {
        _projects = loaded.projects.toList();
        _boxes = loaded.boxes.toList();
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
      items: items,
      photoPaths: photoPaths,
      isPriority: isPriority,
      createdAt: now,
      updatedAt: now,
    );
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final nextProjects = oldProjects.toList();
    nextProjects[projectIndex] = project.copyWith(
      nextSequence: project.nextSequence + 1,
      updatedAt: now,
    );
    _projects = nextProjects;
    _boxes = [...oldBoxes, box];
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      rethrow;
    }
    notifyListeners();
    return box;
  }

  Future<void> updateBox(BoxRecord updated) async {
    final index = _boxes.indexWhere((box) => box.id == updated.id);
    if (index < 0) throw StateError('Box not found');
    final code = updated.shortCode.trim().toUpperCase();
    if (!isCodeAvailable(updated.projectId, code, excludingId: updated.id)) {
      throw DuplicateBoxCodeException();
    }
    final previous = _boxes;
    final next = previous.toList();
    next[index] = updated.copyWith(
      shortCode: code,
      title: updated.title.trim(),
      destinationRoom: updated.destinationRoom.trim(),
      currentLocation: updated.currentLocation.trim(),
      memo: updated.memo.trim(),
      tags: _cleanList(updated.tags),
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

  Future<void> deleteBox(String id) async {
    final previous = _boxes;
    _boxes = _boxes.where((box) => box.id != id).toList();
    try {
      await _persist();
    } catch (_) {
      _boxes = previous;
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
    _projects = _projects.where((project) => project.id != id).toList();
    _boxes = _boxes.where((box) => box.projectId != id).toList();
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
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
    );
  }

  Uint8List exportBackup() => _snapshot().toBytes();

  Future<void> importBackup(List<int> bytes) async {
    final imported = AppSnapshot.fromBytes(bytes);
    final oldProjects = _projects;
    final oldBoxes = _boxes;
    final oldSeeded = _hasSeededExample;
    _projects = imported.projects.toList();
    _boxes = imported.boxes.toList();
    _hasSeededExample = imported.hasSeededExample;
    try {
      await _persist();
    } catch (_) {
      _projects = oldProjects;
      _boxes = oldBoxes;
      _hasSeededExample = oldSeeded;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _persist() => _repository.save(_snapshot());

  AppSnapshot _snapshot() => AppSnapshot(
    projects: _projects,
    boxes: _boxes,
    hasSeededExample: _hasSeededExample,
  );
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
