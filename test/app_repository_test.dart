import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/models/box_record.dart';
import 'package:moving_box/models/moving_project.dart';

void main() {
  late Directory temporary;
  late FileAppRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('moving-box-repository-');
    repository = FileAppRepository(supportDirectory: () async => temporary);
  });

  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  test(
    'managed photo paths are portable on disk and current after load',
    () async {
      final currentPhoto = File(
        '${temporary.path}/moving_box/photos/photo.jpg',
      );
      await currentPhoto.parent.create(recursive: true);
      await currentPhoto.writeAsBytes([1, 2, 3]);
      final snapshot = _snapshotWithPhoto(currentPhoto.path);

      await repository.save(snapshot);

      final dataFile = File('${temporary.path}/moving_box/app_data.json');
      final json =
          jsonDecode(await dataFile.readAsString()) as Map<String, Object?>;
      final boxes = json['boxes']! as List<Object?>;
      final box = boxes.single! as Map<String, Object?>;
      expect(box['photoPaths'], ['photos/photo.jpg']);
      expect((await repository.load())!.boxes.single.photoPaths, [
        currentPhoto.path,
      ]);
    },
  );

  test(
    'legacy iOS container paths are rebased to the current container',
    () async {
      final legacyPath =
          '/var/mobile/Containers/Data/Application/OLD/Library/'
          'Application Support/moving_box/photos/legacy.jpg';
      final dataFile = File('${temporary.path}/moving_box/app_data.json');
      await dataFile.parent.create(recursive: true);
      await dataFile.writeAsBytes(_snapshotWithPhoto(legacyPath).toBytes());

      final loaded = await repository.load();

      expect(loaded!.boxes.single.photoPaths, [
        '${temporary.path}/moving_box/photos/legacy.jpg',
      ]);
    },
  );
}

AppSnapshot _snapshotWithPhoto(String photoPath) {
  final now = DateTime.utc(2026, 8, 28);
  return AppSnapshot(
    projects: [
      MovingProject(
        id: 'project-1',
        name: 'Move',
        origin: 'Old home',
        destination: 'New home',
        boxPrefix: 'C',
        nextSequence: 2,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    boxes: [
      BoxRecord(
        id: 'box-1',
        projectId: 'project-1',
        shortCode: 'C-001',
        photoPaths: [photoPath],
        createdAt: now,
        updatedAt: now,
      ),
    ],
    hasSeededExample: true,
  );
}
