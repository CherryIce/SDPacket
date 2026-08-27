import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';
import 'package:moving_box/models/box_record.dart';
import 'package:moving_box/models/entry_batch.dart';
import 'package:moving_box/services/backup_service.dart';

const _seed = SampleSeed(
  projectName: 'Sample',
  origin: 'Origin',
  destination: 'Destination',
  memo: 'Coffee maker and cups',
);

void main() {
  group('AppStore numbering and persistence', () {
    test('persists the selected language independently of app data', () async {
      final repository = InMemoryAppRepository();
      final store = AppStore(repository: repository, initialLanguageCode: 'en');
      await store.initialize(_seed);

      await store.setLanguageCode('zh');

      final reloaded = AppStore(
        repository: repository,
        initialLanguageCode: 'en',
      );
      await reloaded.initialize(_seed);
      expect(reloaded.languageCode, 'zh');
    });

    test('persists onboarding completion independently of app data', () async {
      final repository = InMemoryAppRepository();
      final store = AppStore(repository: repository);
      await store.initialize(_seed);

      expect(store.hasCompletedOnboarding, isFalse);
      await store.completeOnboarding();

      final reloaded = AppStore(repository: repository);
      await reloaded.initialize(_seed);
      expect(reloaded.hasCompletedOnboarding, isTrue);
    });

    test('keeps the previous language when preference storage fails', () async {
      final store = AppStore(
        repository: _FailingLanguageRepository(),
        initialLanguageCode: 'en',
      );
      await store.initialize(_seed);

      expect(store.isReady, isTrue);
      await expectLater(store.setLanguageCode('zh'), throwsStateError);
      expect(store.languageCode, 'en');
    });

    test('seeds once and never reuses deleted numbers', () async {
      final repository = InMemoryAppRepository();
      final store = AppStore(repository: repository);
      await store.initialize(_seed);

      final project = store.activeProjects.single;
      expect(store.boxesForProject(project.id).single.shortCode, 'C-001');

      final second = await store.createBox(projectId: project.id);
      final third = await store.createBox(projectId: project.id);
      expect(second.shortCode, 'C-002');
      expect(third.shortCode, 'C-003');

      await store.deleteBox(second.id);
      final fourth = await store.createBox(projectId: project.id);
      expect(fourth.shortCode, 'C-004');

      await store.deleteProject(project.id);
      final reloaded = AppStore(repository: repository);
      await reloaded.initialize(_seed);
      expect(reloaded.activeProjects, isEmpty);
    });

    test('rejects duplicate codes inside one project', () async {
      final store = AppStore(repository: InMemoryAppRepository());
      await store.initialize(_seed);
      final project = store.activeProjects.single;
      final second = await store.createBox(projectId: project.id);
      final first = store.boxesForProject(project.id).last;

      expect(
        () => store.updateBox(second.copyWith(shortCode: first.shortCode)),
        throwsA(isA<DuplicateBoxCodeException>()),
      );
    });

    test('searches notes, structured items, room and tags offline', () async {
      final store = AppStore(repository: InMemoryAppRepository());
      await store.initialize(_seed);
      final project = store.activeProjects.single;
      final box = await store.createBox(
        projectId: project.id,
        destinationRoom: 'Kitchen',
        memo: 'Power cable',
        tags: const ['Fragile'],
        items: const [BoxItem(id: 'item-1', name: 'Coffee grinder')],
      );

      for (final query in ['kitchen', 'cable', 'fragile', 'grinder']) {
        expect(store.searchAll(query).map((item) => item.id), contains(box.id));
      }
    });

    test(
      'progress treats later move states as completing earlier stages',
      () async {
        final store = AppStore(repository: InMemoryAppRepository());
        await store.initialize(_seed);
        final project = store.activeProjects.single;
        final box = await store.createBox(projectId: project.id);
        await store.updateBox(
          box.copyWith(
            moveStatus: MoveStatus.arrived,
            issues: const {BoxIssue.suspectedMissing},
          ),
        );

        final stats = store.statsFor(project.id);
        expect(stats.packed, 2);
        expect(stats.loaded, 1);
        expect(stats.arrived, 1);
        expect(stats.unpacked, 0);
        expect(stats.suspectedMissing, 1);
      },
    );

    test('invalid backup never replaces current data', () async {
      final store = AppStore(repository: InMemoryAppRepository());
      await store.initialize(_seed);
      final before = store.activeProjects.single.id;

      expect(
        () => store.importBackup(utf8.encode('{"schemaVersion":999}')),
        throwsA(isA<FormatException>()),
      );
      expect(store.activeProjects.single.id, before);

      final bytes = store.exportBackup();
      final restored = AppStore(repository: InMemoryAppRepository());
      await restored.initialize(_seed);
      await restored.importBackup(bytes);
      expect(restored.activeProjects.single.id, before);
    });

    test('backup round trips Chinese text as valid UTF-8', () async {
      final store = AppStore(repository: InMemoryAppRepository());
      await store.initialize(_seed);
      final project = await store.createProject(
        name: '跨城搬家',
        origin: '上海',
        destination: '杭州',
      );
      await store.createBox(projectId: project.id, memo: '咖啡机、杯子和滤纸');

      final restored = AppStore(repository: InMemoryAppRepository());
      await restored.initialize(_seed);
      await restored.importBackup(store.exportBackup());

      final imported = restored.projectById(project.id);
      expect(imported.name, '跨城搬家');
      expect(restored.boxesForProject(project.id).single.memo, '咖啡机、杯子和滤纸');
    });

    test(
      'unfinished entry batch survives reload and resumes at next box',
      () async {
        final repository = InMemoryAppRepository();
        final store = AppStore(repository: repository);
        await store.initialize(_seed);
        final project = store.activeProjects.single;
        final batch = await store.createEntryBatch(
          projectId: project.id,
          source: EntryBatchSource.gallery,
        );
        final first = await store.createBox(
          projectId: project.id,
          entryBatchId: batch.id,
        );
        final second = await store.createBox(
          projectId: project.id,
          entryBatchId: batch.id,
        );
        await store.advanceEntryBatch(batch.id, 1);

        final reloaded = AppStore(repository: repository);
        await reloaded.initialize(_seed);
        final resumed = reloaded.activeEntryBatchForProject(project.id);
        expect(resumed?.boxIds, [first.id, second.id]);
        expect(resumed?.nextIndex, 1);

        await reloaded.applyEntryBatchDetails(
          batch.id,
          fromIndex: 1,
          destinationRoom: 'Kitchen',
          tags: const ['Fragile'],
        );
        expect(reloaded.boxById(first.id)?.destinationRoom, isEmpty);
        expect(reloaded.boxById(second.id)?.destinationRoom, 'Kitchen');
        expect(reloaded.boxById(second.id)?.tags, ['Fragile']);

        await reloaded.finishEntryBatch(batch.id);
        expect(reloaded.activeEntryBatchForProject(project.id), isNull);
      },
    );

    test('schema v1 JSON backups remain importable', () async {
      final store = AppStore(repository: InMemoryAppRepository());
      await store.initialize(_seed);
      final legacy = jsonDecode(utf8.decode(store.exportBackup())) as Map;
      legacy['schemaVersion'] = 1;
      legacy.remove('entryBatches');

      final restored = AppStore(repository: InMemoryAppRepository());
      await restored.initialize(_seed);
      await restored.importBackup(utf8.encode(jsonEncode(legacy)));

      expect(restored.activeProjects.single.name, 'Sample');
      expect(restored.allEntryBatches, isEmpty);
    });

    test('records status source and can undo the latest change', () async {
      final repository = InMemoryAppRepository();
      final store = AppStore(repository: repository);
      await store.initialize(_seed);
      final project = store.activeProjects.single;
      final box = await store.createBox(projectId: project.id);

      await store.updateBox(box.copyWith(moveStatus: MoveStatus.packed));
      final packed = store.boxById(box.id)!;
      expect(packed.statusHistory, hasLength(1));
      expect(packed.statusHistory.single.from, MoveStatus.draft);
      expect(packed.statusHistory.single.to, MoveStatus.packed);
      expect(packed.statusHistory.single.source, StatusChangeSource.manual);

      await store.updateBox(
        packed.copyWith(moveStatus: MoveStatus.loaded),
        statusSource: StatusChangeSource.scanner,
      );
      expect(
        store.boxById(box.id)!.statusHistory.last.source,
        StatusChangeSource.scanner,
      );

      await store.undoLastStatusChange(box.id);
      final undone = store.boxById(box.id)!;
      expect(undone.moveStatus, MoveStatus.packed);
      expect(undone.statusHistory, hasLength(1));

      final reloaded = AppStore(repository: repository);
      await reloaded.initialize(_seed);
      expect(reloaded.boxById(box.id)?.statusHistory, hasLength(1));
    });

    test(
      'preserves structured item quantity, note and unpacked state',
      () async {
        final store = AppStore(repository: InMemoryAppRepository());
        await store.initialize(_seed);
        final project = store.activeProjects.single;
        final box = await store.createBox(
          projectId: project.id,
          items: const [
            BoxItem(
              id: 'item-complete',
              name: 'Coffee cup',
              quantity: 2,
              note: 'Blue cups',
              isUnpacked: true,
            ),
          ],
        );
        final restored = AppStore(repository: InMemoryAppRepository());
        await restored.initialize(_seed);
        await restored.importBackup(store.exportBackup());

        final item = restored.boxById(box.id)!.items.single;
        expect(item.name, 'Coffee cup');
        expect(item.quantity, 2);
        expect(item.note, 'Blue cups');
        expect(item.isUnpacked, isTrue);
      },
    );

    test(
      'offers recent rooms, locations and tags without duplicates',
      () async {
        final store = AppStore(repository: InMemoryAppRepository());
        await store.initialize(_seed);
        final project = store.activeProjects.single;
        await store.createBox(
          projectId: project.id,
          destinationRoom: 'Kitchen',
          currentLocation: 'Old home',
          tags: const ['Fragile', 'Keep dry'],
        );
        await store.createBox(
          projectId: project.id,
          destinationRoom: 'kitchen',
          currentLocation: 'Truck',
          tags: const ['fragile'],
        );

        expect(store.recentRoomsForProject(project.id).first, 'kitchen');
        expect(store.recentLocationsForProject(project.id), [
          'Truck',
          'Old home',
        ]);
        expect(store.recentTagsForProject(project.id), ['fragile', 'Keep dry']);
      },
    );
  });

  group('photo backup package', () {
    late Directory temporary;
    late Directory sourceSupport;
    late Directory restoredSupport;

    setUp(() async {
      temporary = await Directory.systemTemp.createTemp('moving-box-backup-');
      sourceSupport = Directory('${temporary.path}/source');
      restoredSupport = Directory('${temporary.path}/restored');
      await sourceSupport.create(recursive: true);
      await restoredSupport.create(recursive: true);
    });

    tearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });

    test(
      'packages photo bytes and restores them to a new local path',
      () async {
        final photo = File('${sourceSupport.path}/photo.jpg');
        await photo.writeAsBytes([1, 2, 3, 4, 5]);
        final source = AppStore(
          repository: InMemoryAppRepository(),
          backupService: BackupService(
            supportDirectory: () async => sourceSupport,
          ),
        );
        await source.initialize(_seed);
        final project = source.activeProjects.single;
        final box = await source.createBox(
          projectId: project.id,
          memo: 'Photo box',
          photoPaths: [photo.path],
        );

        final package = await source.exportBackupPackage();
        final restored = AppStore(
          repository: InMemoryAppRepository(),
          backupService: BackupService(
            supportDirectory: () async => restoredSupport,
          ),
        );
        await restored.initialize(_seed);
        final missing = await restored.importBackupPackage(package);
        final importedPath = restored.boxById(box.id)!.photoPaths.single;

        expect(missing, 0);
        expect(importedPath, isNot(photo.path));
        expect(importedPath, startsWith(restoredSupport.path));
        expect(await File(importedPath).readAsBytes(), [1, 2, 3, 4, 5]);
      },
    );

    test('rejects a package whose photo checksum no longer matches', () async {
      final photo = File('${sourceSupport.path}/photo.jpg');
      await photo.writeAsBytes([10, 20, 30]);
      final service = BackupService(
        supportDirectory: () async => sourceSupport,
      );
      final source = AppStore(
        repository: InMemoryAppRepository(),
        backupService: service,
      );
      await source.initialize(_seed);
      await source.createBox(
        projectId: source.activeProjects.single.id,
        photoPaths: [photo.path],
      );
      final archive = ZipDecoder().decodeBytes(
        await source.exportBackupPackage(),
      );
      final photoEntry = archive.files.firstWhere(
        (entry) => entry.name.startsWith('photos/'),
      );
      archive.add(ArchiveFile.bytes(photoEntry.name, [99, 20, 30]));
      final corrupted = ZipEncoder().encodeBytes(archive);

      expect(
        () => service.prepareImport(corrupted),
        throwsA(isA<FormatException>()),
      );
    });

    test('reports photos that were already missing during export', () async {
      final source = AppStore(
        repository: InMemoryAppRepository(),
        backupService: BackupService(
          supportDirectory: () async => sourceSupport,
        ),
      );
      await source.initialize(_seed);
      final box = await source.createBox(
        projectId: source.activeProjects.single.id,
        photoPaths: ['${sourceSupport.path}/missing.jpg'],
      );
      final restored = AppStore(
        repository: InMemoryAppRepository(),
        backupService: BackupService(
          supportDirectory: () async => restoredSupport,
        ),
      );
      await restored.initialize(_seed);

      final missing = await restored.importBackupPackage(
        await source.exportBackupPackage(),
      );

      expect(missing, 1);
      expect(restored.boxById(box.id)?.photoPaths, isEmpty);
    });
  });
}

class _FailingLanguageRepository extends InMemoryAppRepository {
  @override
  Future<String?> loadLanguageCode() => throw StateError('Unavailable');

  @override
  Future<void> saveLanguageCode(String languageCode) =>
      throw StateError('Unavailable');
}
