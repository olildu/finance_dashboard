import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/custom_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> titles = [
  "Left for the month",
  "Savings",
  "Variable Expense",
  "Mutual Funds"
];

List<String> chipText = [
  "/ day",
  "this month",
  "this month",
  "this month"
];

int calculatePerDayUsage(int balance, int daysLeft) {
  if (daysLeft == 0) {
    throw ArgumentError("Days left cannot be zero");
  }
  return balance ~/ daysLeft;
}

Widget yourPortFolioWidget(List data) {
  return SizedBox(
    height: 150.h,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      itemBuilder: (context, index) {
        return portFolioChildren(index, data[index]);
      },
    ),
  );
}

Widget portFolioChildren(int index, int value){
  DateTime now = DateTime.now();
  int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
  int daysLeft = totalDaysInMonth - now.day + 1;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
      width: 250.w,
      height: 50.h,
      margin: EdgeInsets.only(right: 10.w, top: 10.h),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(15.r)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            titles[index],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              fontSize: 18.sp
            ),
          ),

          Text(
            "₹ ${formatIndianSystem(value)}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 24.sp
            ),
          ),   

          Gap(15.h),

          customChip("${formatIndianSystem(calculatePerDayUsage(value, daysLeft))} ${chipText[index]}")  
        ],
      ),
    );
}