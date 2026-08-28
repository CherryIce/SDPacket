import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosActionSheetOption<T> {
  const IosActionSheetOption({
    required this.label,
    required this.value,
    this.isDestructive = false,
    this.isSelected = false,
  });

  final String label;
  final T value;
  final bool isDestructive;
  final bool isSelected;
}

Future<T?> showIosActionSheet<T>({
  required BuildContext context,
  required String cancelLabel,
  required List<IosActionSheetOption<T>> options,
  String? title,
  String? message,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    semanticsDismissible: true,
    builder: (sheetContext) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: options
          .map(
            (option) => CupertinoActionSheetAction(
              isDestructiveAction: option.isDestructive,
              onPressed: () => Navigator.pop(sheetContext, option.value),
              child: _IosActionSheetLabel(option: option),
            ),
          )
          .toList(growable: false),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(sheetContext),
        child: Text(cancelLabel),
      ),
    ),
  );
}

class _IosActionSheetLabel<T> extends StatelessWidget {
  const _IosActionSheetLabel({required this.option});

  final IosActionSheetOption<T> option;

  @override
  Widget build(BuildContext context) {
    if (!option.isSelected) return Text(option.label);
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Text(option.label, textAlign: TextAlign.center),
        ),
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Icon(CupertinoIcons.check_mark, size: 19),
        ),
      ],
    );
  }
}

Future<bool> showIosConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: !isDestructive,
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showIosInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String closeLabel,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}

Future<T?> showIosFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

Future<T?> showIosFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    semanticsDismissible: true,
    builder: builder,
  );
}

class IosFormDialogAction {
  const IosFormDialogAction({
    required this.label,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructive = false,
    this.child,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDefaultAction;
  final bool isDestructive;
  final Widget? child;
}

InputDecoration iosFormFieldDecoration(
  BuildContext context, {
  required String label,
}) {
  final colors = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(14);
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.error, width: 2),
    ),
  );
}

class IosFormDialog extends StatelessWidget {
  const IosFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<IosFormDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        (mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48)
            .clamp(120.0, mediaQuery.size.height - 48)
            .toDouble();
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final surfaceColor = CupertinoColors.systemBackground.resolveFrom(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + mediaQuery.viewInsets.bottom,
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: CupertinoPopupSurface(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360, maxHeight: maxHeight),
              child: ColoredBox(
                color: surfaceColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: separatorColor),
                    Flexible(child: content),
                    Divider(height: 0.5, thickness: 0.5, color: separatorColor),
                    SizedBox(
                      height: 50,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var index = 0; index < actions.length; index++)
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: index == 0
                                      ? null
                                      : BorderDirectional(
                                          start: BorderSide(
                                            color: separatorColor,
                                            width: 0.5,
                                          ),
                                        ),
                                ),
                                child: _IosFormDialogButton(
                                  action: actions[index],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosFormSheet extends StatelessWidget {
  const IosFormSheet({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<IosFormDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - keyboardHeight - mediaQuery.padding.top - 12;
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final surfaceColor = CupertinoColors.systemGroupedBackground.resolveFrom(
      context,
    );
    final handleColor = CupertinoColors.systemGrey3.resolveFrom(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: availableHeight.clamp(140.0, double.infinity),
            ),
            child: ClipRRect(
              key: const Key('ios-form-sheet-surface'),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: ColoredBox(
                color: surfaceColor,
                child: SafeArea(
                  top: false,
                  bottom: keyboardHeight == 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: handleColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: separatorColor,
                      ),
                      Flexible(child: content),
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: separatorColor,
                      ),
                      SizedBox(
                        key: const Key('ios-form-sheet-actions'),
                        height: 54,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0; index < actions.length; index++)
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: index == 0
                                        ? null
                                        : BorderDirectional(
                                            start: BorderSide(
                                              color: separatorColor,
                                              width: 0.5,
                                            ),
                                          ),
                                  ),
                                  child: _IosFormDialogButton(
                                    action: actions[index],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosFormDialogButton extends StatelessWidget {
  const _IosFormDialogButton({required this.action});

  final IosFormDialogAction action;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onPressed != null;
    final color = !enabled
        ? CupertinoColors.inactiveGray.resolveFrom(context)
        : action.isDestructive
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemBlue.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: action.onPressed,
      child:
          action.child ??
          Text(
            action.label,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: action.isDefaultAction
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
    );
  }
}

Future<T?> showIosBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    semanticsDismissible: true,
    builder: (sheetContext) => IosBottomSheet(child: builder(sheetContext)),
  );
}

class IosBottomSheet extends StatelessWidget {
  const IosBottomSheet({
    super.key,
    required this.child,
    this.showHandle = true,
  });

  final Widget child;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.systemGroupedBackground.resolveFrom(
      context,
    );
    final handle = CupertinoColors.systemGrey3.resolveFrom(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ColoredBox(
            color: background,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: handle,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosSelectionField<T> extends StatelessWidget {
  const IosSelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.cancelLabel,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T value;
  final String valueLabel;
  final String cancelLabel;
  final List<IosActionSheetOption<T>> options;
  final ValueChanged<T> onSelected;

  Future<void> _select(BuildContext context) async {
    final selected = await showIosActionSheet<T>(
      context: context,
      title: label,
      cancelLabel: cancelLabel,
      options: options
          .map(
            (option) => IosActionSheetOption<T>(
              label: option.label,
              value: option.value,
              isDestructive: option.isDestructive,
              isSelected: option.value == value,
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      value: valueLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _select(context),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 18),
          ),
          child: Text(valueLabel),
        ),
      ),
    );
  }
}
