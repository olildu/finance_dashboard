import 'package:finance_dashboard/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

Widget customChip(String amount){
  return Container(
    height: 30.h,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    decoration: BoxDecoration(
      color: secondaryColor,
      borderRadius: BorderRadius.circular(30.r)
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance_outlined, color: Colors.white, size: 18.sp,),

        Gap(5.h),

        Text(
          amount,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w200
          ),
        )
      ],
    ),
  );
}