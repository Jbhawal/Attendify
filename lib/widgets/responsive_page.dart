import 'package:flutter/material.dart';

/// A small helper that centers page content and constrains max width on
/// wide screens. On narrow screens it simply returns the child unchanged.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key, required this.child, this.maxWidth = 920, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width <= maxWidth + 48) {
        // Keep original padding on narrow screens
        return Padding(padding: padding, child: child);
      }
      // Center and constrain on wider screens
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
    });
  }
}
