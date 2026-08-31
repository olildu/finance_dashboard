import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/transactions/mobile_transactions_page.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

Widget summaryWidget(BuildContext context, Map categorySpends, int totalSpent, Map categoryPercentages){
  var date = DateTime.now();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Gap(10.h),
      Container(
        width: double.infinity,
        height: 430.h,
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20.r), 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${months[date.month - 1]} ${date.year}",
                  style: TextStyle(fontSize: 20.sp, color: const Color.fromARGB(255, 254, 254, 254)),
                ),

                const Spacer(),       

                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: const Color.fromARGB(255, 90, 90, 90),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_forward_ios, color: Color.fromARGB(255, 254, 254, 254), size: 13,),
                    onPressed: (){
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const MobileTransactionPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Gap(20.h),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.65,
                            height: MediaQuery.sizeOf(context).height * 0.05, 
                            margin: EdgeInsets.symmetric(vertical: MediaQuery.sizeOf(context).height * 0.02),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 90, 90, 90),
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50.r),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (categoryPercentages[categories[index]] ?? 0.0),
                                heightFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 53, 53, 53),
                                    borderRadius: BorderRadius.circular(20.r), 
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          Transform.translate(
                            offset: Offset(18.w, 20.h),
                            child: Text(
                              categories[index],
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.normal,
                                color: const Color.fromARGB(255, 255, 255, 255)
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(categorySpends[categories[index]] != null
                        ? "-${formatIndianSystem(categorySpends[categories[index]])} ₹"
                        : "-0 ₹",
                        style: TextStyle(fontSize: 15.sp, color: const Color.fromARGB(255, 254, 254, 254)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
