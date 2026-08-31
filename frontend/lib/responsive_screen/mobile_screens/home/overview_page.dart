import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/common_widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class OverviewPage extends StatelessWidget {
  final Map financialData;

  const OverviewPage({
    super.key,
    required this.financialData,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> gridTitles = ["Left for day", "Min left", "Days Left", "Total Spent"];

    List gridValues = [
      "₹ ${formatIndianSystem((((financialData["monthly_expense_left"] + financialData["spent_today"]) / daysLeftInMonth()) - financialData["spent_today"]).toInt())}",
      "₹ ${formatIndianSystem((financialData["monthly_expense_left"] / daysLeftInMonth()).toInt())}",
      "${daysLeftInMonth()} Days",
      "₹ ${formatIndianSystem(financialData["spent_today"])}"
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 700;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview title
            AppText(
              "Overview",
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),

            Gap(20.h),

            // Grid of boxes
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        gridTitles[index],
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                        fontSize: 16.sp,
                        textAlign: TextAlign.left,
                      ),
                      Gap(4.h),
                      Expanded(
                        child: Center(
                          child: AppText(
                            "${(gridValues[index])}",
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w300,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Gap(20.h),

            // Savings text
            AppText(
              "Savings",
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),

            Gap(10.h),

            // Savings card
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 45.sp,
                      color: Colors.white,
                    ),
                    Gap(20.w),
                    AppText(
                      "₹ ${formatIndianSystem(financialData["savings"] ?? 0)}",
                      color: Colors.white,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.all(16.w),
          child: isSmallScreen
              ? SingleChildScrollView(
                  child: content,
                )
              : content,
        );
      },
    );
  }
}
