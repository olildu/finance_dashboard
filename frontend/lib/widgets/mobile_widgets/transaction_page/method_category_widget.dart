import 'package:finance_dashboard/constants/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

Widget methodCategoryClassWidget(String method, String category) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 90, 90, 90),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (categoriesIcon[method] != null) ...[
              if (method == "credit") ...[
                Transform.rotate(
                    angle: 72.3,
                    child: Icon(
                      categoriesIcon[method],
                      color: Colors.white,
                    )),
              ],
              if (method == "debit") ...[
                Icon(
                  categoriesIcon[method],
                  color: Colors.white,
                ),
              ],
              Gap(10.w),
            ],
            Text(
              method.replaceFirstMapped(RegExp(r'^\w'), (Match match) => match.group(0)!.toUpperCase()),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      Gap(10.w),
      Container(
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 90, 90, 90),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (categoriesIcon[category] != null) ...[
              Icon(
                categoriesIcon[category],
                color: Colors.white,
              ),
              Gap(10.w),
            ],
            Text(
              category,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.normal, color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );
}

              // transactions[reuquiredIndex][index]["category"]
//transactions[reuquiredIndex][index]["method"]