import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/app.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';

void main() {
  Future<AppStore> createStore() async {
    final store = AppStore(repository: InMemoryAppRepository.onboarded());
    await store.initialize(
      const SampleSeed(
        projectName: 'Sample move',
        origin: 'Old home',
        destination: 'New home',
        memo: 'Coffee maker',
      ),
    );
    return store;
  }

  Future<void> openManualEntry(WidgetTester tester) async {
    await tester.tap(find.text('Sample move'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manual entry'));
    await tester.pumpAndSettle();
  }

  Finder editorScrollable() => find.descendant(
    of: find.byKey(const Key('box-editor-scroll')),
    matching: find.byType(Scrollable),
  ).first;

  testWidgets('manual entry does not create or consume a box code on cancel', (
    tester,
  ) async {
    final store = await createStore();
    final projectId = store.activeProjects.single.id;
    final originalCount = store.allBoxes.length;
    final originalNextCode = store.nextCode(projectId);

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    await openManualEntry(tester);

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsNothing);
    expect(store.allBoxes, hasLength(originalCount));
    expect(store.nextCode(projectId), originalNextCode);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(store.allBoxes, hasLength(originalCount));
    expect(store.nextCode(projectId), originalNextCode);
  });

  testWidgets('tag template fills the input and is persisted only on save', (
    tester,
  ) async {
    final store = await createStore();
    final originalCount = store.allBoxes.length;

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    await openManualEntry(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('suggestion-Fragile')),
      300,
      scrollable: editorScrollable(),
    );
    await tester.drag(editorScrollable(), const Offset(0, -140));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('suggestion-Fragile')));
    await tester.pump();

    final tagsField = tester.widget<TextField>(
      find.byKey(const Key('box-editor-tags')),
    );
    final selectedChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('suggestion-Fragile')),
    );
    expect(tagsField.controller!.text, 'Fragile');
    expect(tagsField.controller!.selection.baseOffset, 'Fragile'.length);
    expect(selectedChip.selected, isTrue);
    expect(store.allBoxes, hasLength(originalCount));

    await tester.tap(find.byKey(const Key('box-editor-save')));
    await tester.pumpAndSettle();

    expect(store.allBoxes, hasLength(originalCount + 1));
    expect(store.allBoxes.last.tags, ['Fragile']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual editor sections remain scrollable on a narrow display', (
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
    final store = await createStore();

    await tester.pumpWidget(MovingBoxApp(store: store));
    await tester.pumpAndSettle();
    await openManualEntry(tester);

    for (final key in [
      const Key('box-editor-information-section'),
      const Key('box-editor-contents-section'),
      const Key('box-editor-items-section'),
      const Key('box-editor-moving-section'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        280,
        scrollable: editorScrollable(),
      );
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
