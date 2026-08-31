import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/bar_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

Widget centerRow(BuildContext context, List<IconData> iconsCenter, Map financialData, {controller}) {
  List title = ["Left for day", "Min left", "Days Left", "Total Spent"];

  List data = [
    "₹ ${formatIndianSystem((((financialData["monthly_expense_left"] + financialData["spent_today"]) / daysLeftInMonth()) - financialData["spent_today"]).toInt())}",
    "₹ ${formatIndianSystem((financialData["monthly_expense_left"] / daysLeftInMonth()).toInt())}",
    "${daysLeftInMonth()} Days",
    "₹ ${formatIndianSystem(financialData["spent_today"])}"
  ];

  double calculateOptimalRatio(double width, double height) {
    double screenRatio = width / height;
    return screenRatio / 1.66;
  }

  return Expanded(
    flex: 5,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: centerLeftItems(iconsCenter, 0, financialData["monthly_expense_left"]),
                ),
                Gap(10.h),
                Expanded(
                  child: centerLeftItems(iconsCenter, 1, financialData["savings"]),
                ),
              ],
            ),
          ),
          Gap(10.h),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(30.r)),
              child: BarChartSample1(
                financialData: financialData,
              ),
            ),
          ),
          Gap(10.h),
          const VideoWidget(),
          Gap(10.h),
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: calculateOptimalRatio(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title[index],
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 200, 200, 200),
                          fontWeight: FontWeight.w300,
                          fontSize: 22.sp,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            data[index],
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 235, 235, 235),
                              fontWeight: FontWeight.w300,
                              fontSize: 40.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        
        
        ],
      ),
    ),
  );
}

Widget centerLeftItems(iconsCenter, index, data) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(30.r)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(
          iconsCenter[index],
          size: 70.sp,
          color: Colors.white,
        ),
        Text(
          "₹ ${formatIndianSystem(data)}",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 46.sp),
        ),
      ],
    ),
  );
}

class VideoWidget extends StatefulWidget {
  const VideoWidget({super.key});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                child: Image.asset("assets/fd.png"),
              ),
            )),
      ),
    );
  }
}
