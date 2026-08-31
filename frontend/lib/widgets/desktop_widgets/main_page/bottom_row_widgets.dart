import 'package:carousel_slider/carousel_slider.dart';
import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

List title = ["Large", "Mid", "Total Fund"];
List subTitles = ["Invested", "P/L", "After P/L", ""];
List dataMap = ["invested", "turnover",  "current",];

class BottomItems extends StatefulWidget {
  final dynamic data;
  final int index;

  const BottomItems({
    super.key,
    required this.data,
    required this.index,
  });

  @override
  BottomItemsState createState() => BottomItemsState();
}

class BottomItemsState extends State<BottomItems> {
  int currentIndex = 0;
  CarouselSliderController carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        color: primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.index == 2 
              ? "${title[widget.index]} Performance"
              : "${title[widget.index]} Cap Performance",
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 200, 200, 200),
              fontWeight: FontWeight.w300, 
              fontSize: 26.sp,
            ),
          ),
          Expanded(
            child: CarouselSlider(
              carouselController: carouselController,
              options: CarouselOptions(
                height: 100.0,
                aspectRatio: 16 / 9,
                scrollDirection: Axis.horizontal,
                autoPlay: false,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                enlargeFactor: 2,
                enableInfiniteScroll: false,
                padEnds: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    if (index == 3) {
                      carouselController.jumpToPage(0);
                    } else {
                      currentIndex = index;
                    }
                  });
                },
              ),
              items: subTitles.map((subTitle) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "$subTitle : ",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              fontSize: 25.sp,
                            ),
                          ),
                          TextSpan(
                            text: "₹ ${formatIndianSystem(widget.data[dataMap[currentIndex]].toInt())}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 36.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
