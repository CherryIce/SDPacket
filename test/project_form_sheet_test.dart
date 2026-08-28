import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/app.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';
import 'package:moving_box/widgets/ios_modal.dart';

void main() {
  testWidgets('project form stays above the keyboard and reveals its focus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
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
    await tester.tap(find.byKey(const Key('home-create-project')));
    await tester.pumpAndSettle();

    expect(find.byType(IosFormSheet), findsOneWidget);
    expect(find.byType(IosFormDialog), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);

    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('project-name-field')),
        matching: find.byType(TextField),
      ),
    );
    final enabledBorder = nameField.decoration!.enabledBorder;
    expect(enabledBorder, isA<OutlineInputBorder>());
    expect(
      (enabledBorder! as OutlineInputBorder).borderSide.style,
      BorderStyle.solid,
    );

    final initialSheet = tester.getRect(
      find.byKey(const Key('ios-form-sheet-surface')),
    );
    expect(initialSheet.bottom, closeTo(700, 0.1));

    await tester.tap(find.byKey(const Key('project-prefix-field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final keyboardTop = tester.view.physicalSize.height - 300;
    final adjustedSheet = tester.getRect(
      find.byKey(const Key('ios-form-sheet-surface')),
    );
    final actions = tester.getRect(
      find.byKey(const Key('ios-form-sheet-actions')),
    );
    final focusedField = tester.getRect(
      find.byKey(const Key('project-prefix-field')),
    );
    expect(adjustedSheet.bottom, closeTo(keyboardTop, 0.1));
    expect(focusedField.bottom, lessThanOrEqualTo(actions.top));
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, 'Cancel'));
    await tester.pumpAndSettle();
  });
}
