import 'package:flutter/material.dart';

class BuildText extends StatelessWidget {
  final String? text;
  final double? fontSize;

  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final Color? color;
  final TextDecoration? decoration;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextDirection? textDirection;
  final TextOverflow? overflow;
  final double? height;

  const BuildText({
    super.key,
    this.text,
    this.fontSize,

    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.color,
    this.decoration,
    this.textAlign,
    this.maxLines,
    this.textDirection,
    this.overflow,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? '',
      textAlign: textAlign,

      maxLines: maxLines,
      textDirection: textDirection,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize ?? 16,
        fontStyle: fontStyle,
        fontFamily: fontFamily,
        height: height,
        decoration: decoration,
        color: color,
        fontWeight: fontWeight ?? FontWeight.w400,
      ),
    );
  }
}
