import 'package:finance_dashboard/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

AppBar appBar(BuildContext context) {
  Color textBoxColor = const Color.fromARGB(255, 90, 90, 90);
  return AppBar(
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    backgroundColor: backgroundColor,
    toolbarHeight: 140.h,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Gap(10.h),
        Row(
          children: [
            if (Navigator.of(context).canPop())...[
              CircleAvatar(
                radius: 16.r,
                backgroundColor: primaryColor,
                child: IconButton(
                  onPressed: () {
                    GoRouter.of(context).push('/');
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),

              Gap(10.w),
            ],
            if (!Navigator.of(context).canPop())...[
              CircleAvatar(
                radius: 16.r,
                backgroundColor: primaryColor,
                child: IconButton(
                  onPressed: () {
                    GoRouter.of(context).push('/');
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),

              Gap(20.w),
            ],

            Text(
              "Transactions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
                color: Colors.white
              ),
            ),
          ],
        ),
        Gap(15.h),
        TextField(
          onChanged: (value) {
          },
          decoration: InputDecoration(
            hintText: 'Search transactions',
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 24.sp,
              color: Colors.white,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.r),
              borderSide: BorderSide(width: 1.w, color: textBoxColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.r),
              borderSide: BorderSide(width: 1.5.w, color: textBoxColor),
            ),
            fillColor: textBoxColor,
            filled: true,
          ),
        ),
      ],
    ),
  );
}
