import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget title(String title, {double? size}) {
  return Text(
    title,
    style: TextStyle(fontSize: size ?? 25.sp, color: Colors.white),
  );
}
