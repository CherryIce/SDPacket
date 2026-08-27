import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/app.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';
import 'package:moving_box/theme/app_theme.dart';

void main() {
  test(
    'light and dark themes expose matching brightness and distinct surfaces',
    () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(
        AppTheme.light.colorScheme.surface,
        isNot(AppTheme.dark.colorScheme.surface),
      );
      expect(
        AppTheme.dark.cardTheme.color,
        isNot(AppTheme.dark.scaffoldBackgroundColor),
      );
    },
  );

  testWidgets('app follows system appearance changes at runtime', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(Theme.of(scaffoldContext).brightness, Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
    expect(
      Theme.of(scaffoldContext).scaffoldBackgroundColor,
      AppTheme.dark.scaffoldBackgroundColor,
    );
    expect(tester.takeException(), isNull);
  });
}
