import 'package:carousel_slider/carousel_slider.dart';
import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/debit_credit_method.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> subTitiles = ["Total Balance", "", "Variable Expense", "Mutual Funds"];

Widget topRow(context, List<IconData> iconsTop, Map financialData) {
  return Expanded(
    flex: 3,
    child: Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        topCardItems(context, 0, iconsTop,
            (financialData["savings"] + financialData["monthly_expense_left"] + financialData["variable_expense"] + financialData["mutual_funds_performance"]["total"]["current"].toInt())),
        SlidableBankDetailsWidget(index: 1, iconsTop: iconsTop, data: financialData),
        topCardItems(context, 2, iconsTop, financialData["variable_expense"]),
        topCardItems(context, 3, iconsTop, financialData["mutual_funds_performance"]["total"]["current"].toInt()),
      ],
    )),
  );
}

Widget topCardItems(BuildContext context, index, iconsTop, data) {
  return Container(
    width: 360.w,
    height: 250.h,
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(30.r)),
    child: Stack(
      children: [
        index == 3
            ? Positioned(
                right: 0,
                child: Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const DebitCreditMethod(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 25.sp,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              iconsTop[index],
              size: 55.sp,
              color: Colors.white,
            ),
            Text(
              "₹ ${formatIndianSystem(data)}",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 36.sp),
            ),
            Text(
              subTitiles[index],
              style: GoogleFonts.poppins(color: const Color.fromARGB(255, 200, 200, 200), fontWeight: FontWeight.w300, fontSize: 26.sp),
            ),
          ],
        ),
      ],
    ),
  );
}

class SlidableBankDetailsWidget extends StatefulWidget {
  final int index;
  final List<IconData> iconsTop;
  final Map data;
  const SlidableBankDetailsWidget({
    super.key,
    required this.index,
    required this.iconsTop,
    required this.data,
  });

  @override
  State<SlidableBankDetailsWidget> createState() => _SlidableBankDetailsWidgetState();
}

class _SlidableBankDetailsWidgetState extends State<SlidableBankDetailsWidget> {
  int currentIndex = 0;

  final List<String> banks = ["SBI", "ICICI"];
  List<int> dataIndexes = [];

  @override
  void initState() {
    dataIndexes = [widget.data["savings"] + widget.data["variable_expense"], widget.data["monthly_expense_left"]];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360.w,
      height: 250.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 25.h,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentIndex == 1 ? const Color.fromARGB(255, 128, 128, 128) : const Color.fromARGB(255, 211, 211, 211),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Gap(5.h),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentIndex == 0 ? const Color.fromARGB(255, 128, 128, 128) : const Color.fromARGB(255, 211, 211, 211),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CarouselSlider(
            options: CarouselOptions(
              height: 1400.0,
              aspectRatio: 9 / 16,
              scrollDirection: Axis.vertical,
              enlargeCenterPage: true,
              enlargeFactor: 1.2,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
            items: banks.map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(widget.iconsTop[widget.index], size: 55.sp, color: Colors.white),
                      Text(
                        "₹ ${formatIndianSystem(dataIndexes[currentIndex])}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 36.sp,
                        ),
                      ),
                      Text(
                        "$i Bank Balance",
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 200, 200, 200),
                          fontWeight: FontWeight.w300,
                          fontSize: 26.sp,
                        ),
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
