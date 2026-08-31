import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

AppBar mainPageAppBar() {
  DateTime now = DateTime.now();
  int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
  int daysLeft = totalDaysInMonth - now.day + 1;
  return AppBar(
    scrolledUnderElevation: 0,
    toolbarHeight: 100.sp,
    backgroundColor: backgroundColor,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Gap(10.h),

        Row(
          children: [ 
            CircleAvatar(radius: 20.r),
            Gap(10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ebin Santhosh",
                  style: TextStyle(fontSize: 20.sp), 
                ),
                Text(
                  "$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left in ${months[now.month - 1]}",
                  style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                )
              ],
            ),
          ],
        ),

        Gap(10.h),

        const Divider(endIndent: 5, indent: 5, color: Color.fromARGB(255, 228, 228, 228),)
      ],
    ),
  );
}
