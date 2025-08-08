import 'package:flutter/material.dart';

class ShowCircular extends StatelessWidget {
  final bool visible;
  final double? strokeWidth;
  final double? height;
  final double? width;

  const ShowCircular({
    super.key,
    required this.visible,
    this.strokeWidth,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Visibility(
      visible: visible,
      child: SizedBox(
        height: height,
        width: width,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 4,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
