import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finance_dashboard/core/theme/colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get balanceDisplay => GoogleFonts.poppins(
        fontSize: 50,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  static TextStyle get cardNumber => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        color: Colors.white,
      );

  static TextStyle get cardSubtitle => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w300,
        color: mutedTextColor,
      );

  static TextStyle get sectionLabel => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: mutedTextColor,
      );

  static TextStyle get bodyMuted => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mutedTextColor,
      );
}
