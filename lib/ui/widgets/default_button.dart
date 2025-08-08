import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/show_circular.dart';
import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  final String text;
  final Function press;
  final bool? isLoading, isFullWidth;
  final Color? bgColor, btnTextColor, borderColor;
  final double? btnTextFontSize;
  final FontWeight? fontWeight;

  const DefaultButton({
    super.key,
    required this.text,
    required this.press,
    this.isLoading,
    this.bgColor,
    this.borderColor,
    this.btnTextFontSize,
    this.btnTextColor,
    this.fontWeight,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return isLoading == true
        ? ShowCircular(visible: true)
        : SizedBox(
            width: isFullWidth == true ? double.infinity : null,
            child: ElevatedButton(
              style: ButtonStyle(
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  bgColor ?? colorScheme.primary,
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return colorScheme.onPrimary.withAlpha(32);
                  }
                  return null;
                }),
                foregroundColor: WidgetStateProperty.all(
                  btnTextColor ?? colorScheme.onPrimary,
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(72),
                    side: BorderSide(color: borderColor ?? colorScheme.primary),
                  ),
                ),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                press();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: BuildText(
                  text: text,
                  fontSize: btnTextFontSize ?? 16,
                  fontWeight: fontWeight ?? FontWeight.w500,
                ),
              ),
            ),
          );
  }
}
