import 'package:flutter/material.dart';

/// Switches between a mobile and desktop widget at the same breakpoint
/// used across the app's design reference (width > 800 = desktop).
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({super.key, required this.mobile, required this.desktop});

  static const double breakpoint = 800;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > breakpoint;

  @override
  Widget build(BuildContext context) {
    return isDesktop(context) ? desktop : mobile;
  }
}
