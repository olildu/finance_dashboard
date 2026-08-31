import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';


Widget monthTransactionNumber(int transactionNumber, String transactionDropddown, String month, void Function(int value, String transactionDropdown) changeTransactionTimeLine, void Function(String value) changeMonth) {
  List<List<String>> backendRoutesList = [
    ["all", "All"],
    ["monthly-transactions", "Monthly Transactions"],
    ["variable-expense-transactions", "Variable Expense Transactions"],
    ["savings-expense-transactions", "Savings Expense Transactions"],
  ];
  var textStyle = TextStyle(fontSize: 15.sp, color: Colors.white);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 35.w),
    child: Column(
      children: [
        Row(
          children: [

            Text(
              "$month 2024",
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                color: Colors.white
              ),
            ),

            // Expanded(
            //   child: CustomDropdown<String>(
            //     closedHeaderPadding: EdgeInsets.zero,
            //     excludeSelected: true,
            //     enabled: false,
            //     decoration: CustomDropdownDecoration(
            //       closedBorderRadius: BorderRadius.circular(15.r),
            //       expandedBorderRadius: BorderRadius.circular(15.r),
            //       closedFillColor: Colors.transparent,
            //       expandedFillColor: Color.fromARGB(255, 90, 90, 90),
            //       closedSuffixIcon: SizedBox.shrink(),
            //       hintStyle: textStyle,
            //       listItemStyle: textStyle,
            //       headerStyle: textStyle,
            //     ),
            //     hintText: month,
            //     items: months,
            //     onChanged: (value) {
            //       changeMonth(value!);
            //     },
            //   ),
            // ),
  
            Expanded(
              flex: 2,
              child: StatefulBuilder(
                builder: (context, x) {
                  return CustomDropdown<String>(
                    closedHeaderPadding: EdgeInsets.zero,
                    excludeSelected: true,
                    decoration: CustomDropdownDecoration(
                      closedBorderRadius: BorderRadius.circular(15.r),
                      expandedBorderRadius: BorderRadius.circular(15.r),
                      closedFillColor: Colors.transparent,
                      expandedFillColor: const Color.fromARGB(255, 90, 90, 90),
                      closedSuffixIcon: const SizedBox.shrink(),
                      hintStyle: textStyle,
                      listItemStyle: textStyle,
                      headerStyle: textStyle,
                    ),
                    hintText: transactionDropddown,
                    hintBuilder: (context, hint, enabled) {
                      return Text(
                        hint,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          color: Colors.white
                        ),
                        textAlign: TextAlign.right,
                      );
                    },
                    items: [backendRoutesList[0][1], backendRoutesList[1][1], backendRoutesList[2][1], backendRoutesList[3][1]],
                    onChanged: (value) {
                      changeTransactionTimeLine(
                        backendRoutesList.indexWhere((element) => element[1] == value),
                        value!
                      );
                    },
                  );
                }
              ),
            ),
          
          ],
        ),
        Gap(5.h),
        Divider(
          thickness: 1.5.sp,
          color: const Color.fromARGB(255, 90, 90, 90),
        ),
      ],
    ),
  );
}
