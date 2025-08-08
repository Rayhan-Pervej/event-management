import 'package:flutter/material.dart';

class DefaultHorizontalDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const DefaultHorizontalDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Divider(
      thickness: thickness ?? 1,
      color: color ?? colorScheme.onSurface.withAlpha(60),
      height: height ?? 2,
    );
  }
}
