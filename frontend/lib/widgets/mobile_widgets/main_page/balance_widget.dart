import 'package:finance_dashboard/services/common_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

int calculatePerDayUsage(int balance, int daysLeft) {
  if (daysLeft == 0) {
    throw ArgumentError("Days left cannot be zero");
  }
  return balance ~/ daysLeft;
}

Widget balanceWidget(int balance, int spentToday, int? daysLeftServer) {
  DateTime now = DateTime.now();
  int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
  int daysLeft = totalDaysInMonth - now.day + 1;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Gap(10.h),
      Container(
        width: double.infinity,
        height: 150.h,
        padding: EdgeInsets.all(13.sp), 
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 230, 230, 230),
          borderRadius: BorderRadius.circular(15.r), 
          border: Border.all(
            color: const Color.fromARGB(45, 194, 194, 194),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 197, 197, 197),
                  borderRadius: BorderRadius.circular(15.r)
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Text(
                      "Balance",
                      style: TextStyle(
                        fontSize: 16.sp,
                      ),
                    )),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          "₹ ${formatIndianSystem(balance)}",
                          style: TextStyle(fontSize: 30.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Gap(10.sp),
            
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 197, 197, 197),
                  borderRadius: BorderRadius.circular(15.r)
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Text(
                      "Spent Today",
                      style: TextStyle(
                        fontSize: 16.sp,
                      ),
                    )),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          "₹ ${formatIndianSystem(spentToday)}",
                          style: TextStyle(fontSize: 30.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            
            Gap(10.sp),
            
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 197, 197, 197),
                  borderRadius: BorderRadius.circular(15.r)
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Text(
                      "Month Flow",
                      style: TextStyle(
                        fontSize: 16.sp,
                      ),
                    )),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          "${calculatePerDayUsage(balance, daysLeftServer ?? daysLeft)} ₹ / day",
                          style: TextStyle(
                            fontSize: 23.sp,
                          ), 
                          textAlign: TextAlign.left,
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    
    ],
  );
}