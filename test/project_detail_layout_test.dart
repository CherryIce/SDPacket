import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/app.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';
import 'package:moving_box/screens/box_editor_screen.dart';
import 'package:moving_box/screens/project_detail_screen.dart';

void main() {
  testWidgets('project detail prioritizes search, boxes, and quick entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(
      repository: InMemoryAppRepository.onboarded(),
      initialLanguageCode: 'zh',
    );
    await store.initialize(
      const SampleSeed(
        projectName: '示例搬家',
        origin: '旧家',
        destination: '新家',
        memo: '咖啡机、杯子和滤纸',
      ),
    );
    final project = store.activeProjects.single;
    await store.createBox(
      projectId: project.id,
      destinationRoom: '厨房',
      memo: '餐具',
    );

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        );
    await tester.pumpAndSettle();

    final progress = find.byKey(const Key('project-progress-summary'));
    final search = find.byKey(const Key('project-box-search'));
    final boxes = find.byKey(const Key('project-box-group'));
    final quickEntry = find.byKey(const Key('project-quick-entry-dock'));

    expect(progress, findsOneWidget);
    expect(search, findsOneWidget);
    expect(boxes, findsOneWidget);
    expect(quickEntry, findsOneWidget);
    expect(find.text('C-002'), findsOneWidget);
    expect(find.text('C-001'), findsOneWidget);
    expect(find.text('连续拍照'), findsOneWidget);
    expect(find.text('批量选照片'), findsOneWidget);
    expect(find.text('语音登记'), findsOneWidget);
    expect(find.text('手动登记'), findsOneWidget);

    expect(
      tester.getTopLeft(progress).dy,
      lessThan(tester.getTopLeft(search).dy),
    );
    expect(tester.getTopLeft(search).dy, lessThan(tester.getTopLeft(boxes).dy));
    expect(
      tester.getTopLeft(boxes).dy,
      lessThan(tester.getTopLeft(quickEntry).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('project detail adapts filters and actions for large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final store = AppStore(repository: InMemoryAppRepository.onboarded());
    await store.initialize(
      const SampleSeed(
        projectName: 'Sample move',
        origin: 'Old home',
        destination: 'New home',
        memo: 'Coffee maker',
      ),
    );

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProjectDetailScreen(projectId: store.activeProjects.single.id),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-stage-filters')), findsOneWidget);
    expect(find.byKey(const Key('project-quick-entry-dock')), findsOneWidget);
    expect(find.text('Continuous camera'), findsOneWidget);
    expect(find.text('Choose photos'), findsOneWidget);
    expect(find.text('Voice entry'), findsOneWidget);
    expect(find.text('Manual entry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Manual entry'));
    await tester.pumpAndSettle();
    expect(find.byType(BoxEditorScreen), findsOneWidget);
    expect(store.boxesForProject(store.activeProjects.single.id), hasLength(1));
  });

  testWidgets('English stage filters show complete labels at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(
      repository: InMemoryAppRepository.onboarded(),
      initialLanguageCode: 'en',
    );
    await store.initialize(
      const SampleSeed(
        projectName: 'Sample move',
        origin: 'Old home',
        destination: 'New home',
        memo: 'Coffee maker',
      ),
    );

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProjectDetailScreen(projectId: store.activeProjects.single.id),
          ),
        );
    await tester.pumpAndSettle();

    final filters = find.byKey(const Key('project-stage-filters'));
    expect(filters, findsOneWidget);
    expect(
      find.descendant(of: filters, matching: find.byType(GridView)),
      findsOneWidget,
    );
    for (final label in const [
      'Waiting to load 1',
      'Not arrived 1',
      'Not unpacked 1',
      'Possibly missing 0',
    ]) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
        isFalse,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
