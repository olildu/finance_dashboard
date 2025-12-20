import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final TextDecoration? decoration;
  final bool? softWrap;
  final FontStyle? fontStyle;

  const AppText(
    this.text, {
    super.key,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w400,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.decoration,
    this.softWrap,
    this.fontStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        decoration: decoration,
        fontFamily: GoogleFonts.poppins().fontFamily,
        fontStyle: fontStyle,
      ),
    );
  }
}
