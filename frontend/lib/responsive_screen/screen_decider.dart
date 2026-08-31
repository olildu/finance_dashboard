import 'package:flutter/material.dart';

class ScreenDecider extends StatelessWidget {
  final Widget mobilePage;
  final Widget desktopPage;

  const ScreenDecider({
    super.key,
    required this.mobilePage,
    required this.desktopPage,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 800) {
      return desktopPage;
    } else {
      return mobilePage;
    }
  }
}