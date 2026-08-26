import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';
import 'package:moving_box/models/box_record.dart';

const _seed = SampleSeed(
  projectName: 'Sample',
  origin: 'Origin',
  destination: 'Destination',
  memo: 'Coffee maker and cups',
);

void main() {
  group('AppStore numbering and persistence', () {
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
  });
}
