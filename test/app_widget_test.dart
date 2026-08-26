import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/app.dart';
import 'package:moving_box/data/app_repository.dart';
import 'package:moving_box/data/app_store.dart';

void main() {
  testWidgets('shows the seeded project and core entry points', (tester) async {
    final store = AppStore(repository: InMemoryAppRepository());
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

    expect(find.text('Sample move'), findsOneWidget);
    expect(find.text('Moving projects'), findsOneWidget);

    await tester.tap(find.text('Sample move'));
    await tester.pumpAndSettle();
    expect(find.text('Quick entry'), findsOneWidget);
    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Voice entry'), findsOneWidget);
  });
}
