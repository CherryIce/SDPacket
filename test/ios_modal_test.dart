import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/widgets/ios_modal.dart';

void main() {
  testWidgets('confirmation uses an iOS alert and destructive action', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showIosConfirmation(
                  context: context,
                  title: 'Delete',
                  message: 'Delete this box?',
                  cancelLabel: 'Cancel',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    final destructiveAction = tester.widget<CupertinoDialogAction>(
      find.widgetWithText(CupertinoDialogAction, 'Delete'),
    );
    expect(destructiveAction.isDestructiveAction, isTrue);

    await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('selection field presents an iOS action sheet', (tester) async {
    var selected = 'packed';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => IosSelectionField<String>(
              label: 'Status',
              value: selected,
              valueLabel: selected,
              cancelLabel: 'Cancel',
              options: const [
                IosActionSheetOption(label: 'packed', value: 'packed'),
                IosActionSheetOption(label: 'loaded', value: 'loaded'),
              ],
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('packed'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(CupertinoActionSheetAction, 'loaded'));
    await tester.pumpAndSettle();
    expect(selected, 'loaded');
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });
}
