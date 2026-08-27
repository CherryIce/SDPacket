import 'package:flutter/material.dart';

class AdaptiveActionLayout extends StatelessWidget {
  const AdaptiveActionLayout({
    super.key,
    required this.children,
    this.flexes,
    this.spacing = 12,
    this.horizontalBreakpoint = 330,
  }) : assert(flexes == null || flexes.length == children.length);

  final List<Widget> children;
  final List<int>? flexes;
  final double spacing;
  final double horizontalBreakpoint;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacksVertically =
            constraints.maxWidth < horizontalBreakpoint || textScale > 1.2;
        if (stacksVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spacedChildren(Axis.vertical),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _spacedChildren(Axis.horizontal, expanded: true),
        );
      },
    );
  }

  List<Widget> _spacedChildren(Axis axis, {bool expanded = false}) {
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        result.add(
          SizedBox(
            width: axis == Axis.horizontal ? spacing : 0,
            height: axis == Axis.vertical ? spacing : 0,
          ),
        );
      }
      final child = children[index];
      result.add(
        expanded ? Expanded(flex: flexes?[index] ?? 1, child: child) : child,
      );
    }
    return result;
  }
}
