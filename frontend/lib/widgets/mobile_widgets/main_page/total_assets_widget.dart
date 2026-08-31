import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/custom_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

Widget totalAssetsWidget(Map data){
  int sbiBalance = (data["variable_expense"] + data["savings"]).toInt();
  int iciciBalance = data["monthly_expense_left"].toInt();

  int totalBalance = sbiBalance + iciciBalance;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
    width: double.infinity,
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.circular(30.r)
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Total Balance",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w300
          ),
        ),

        Text(
          "₹ ${formatIndianSystem(totalBalance)}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34.sp
          ),
        ),

        Gap(10.h),

        SizedBox(
          width: 180.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              customChip(formatNumber(sbiBalance.toDouble())),
              customChip(formatNumber(iciciBalance.toDouble())),
            ],
          ),
        ),

      ],
    ),
  );
}