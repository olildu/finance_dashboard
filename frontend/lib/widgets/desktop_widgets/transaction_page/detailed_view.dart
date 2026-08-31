import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/providers/transaction_card_provider.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/transaction_page/method_category_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DetailedView extends StatelessWidget {
  const DetailedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionCardProvider>(
      builder: (context, provider, _) {
        final transactionData = provider.transactionData;

        if (transactionData.isNotEmpty) {
          return Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  color: backgroundColor,
                ),
                child: Column(
                  children: [
                    // Imp Details
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          border: Border.all(
                            color: const Color.fromARGB(255, 82, 82, 82),
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20.r),
                                    topRight: Radius.circular(20.r),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "- ₹ ${formatIndianSystem(3000)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 40.sp,
                                        color: Colors.white,
                                      ),
                                    ),

                                    Gap(20.h),

                                    methodCategoryClassWidget(
                                      transactionData["method"] ?? "",
                                      transactionData["category"] ?? "",
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.h, horizontal: 20.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20.r),
                                        ),
                                        border: const Border(
                                          top: BorderSide(
                                            color: Color.fromARGB(255, 82, 82, 82),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "From",
                                            style: GoogleFonts.poppins(
                                              fontSize: 20.sp,
                                              color: Colors.white,
                                            ),
                                          ),

                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                transactionData["bracket"] == "monthly-transactions"
                                                  ? "ICICI Account"
                                                  : "SBI Account",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 30.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.h, horizontal: 20.w),
                                      decoration: BoxDecoration(
                                        border: const Border(
                                          top: BorderSide(
                                            color: Color.fromARGB(255, 82, 82, 82),
                                          ),
                                          left: BorderSide(
                                            color: Color.fromARGB(255, 82, 82, 82),
                                          ),
                                        ),
                                        borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(20.r),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "On",
                                            style: GoogleFonts.poppins(
                                              fontSize: 23.sp,
                                              color: Colors.white,
                                            ),
                                          ),

                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                transactionData["date"] == null 
                                                  ? "Sun, 25th Jan 25"
                                                  : formatDate(transactionData["date"]),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 23.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
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
                        ),
                      ),
                    ),

                    Gap(10.h),

                    // Reason
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 10.h, horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color.fromARGB(255, 82, 82, 82),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reason",
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                color: Colors.white,
                              ),
                            ),

                            Expanded(
                              child: Center(
                                child: Text(
                                  transactionData["reason"].trim().isEmpty 
                                    ? "No reason provided"
                                    : transactionData["reason"],
                                  style: GoogleFonts.poppins(
                                    fontSize: 28.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Gap(10.h),

                    // Shit Details
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color.fromARGB(255, 82, 82, 82),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        else {
          return Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  color: backgroundColor,
                ),
                child: Center(
                  child: Text(
                    "Select a transaction to view details",
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      color: Colors.white
                    ),
                  )
                ),
              )
            ),
          );
        }


      },
    );
  }
}