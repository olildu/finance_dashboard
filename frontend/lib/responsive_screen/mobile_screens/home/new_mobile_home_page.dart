// lib/responsive_screen/mobile_screens/home/new_mobile_home_page.dart
import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/providers/data_provider.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/debit_credit_method.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/home/switcher_page.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/widgets/common_widgets/text_widget.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

class NewMobileHomePage extends StatefulWidget {
  final bool openPopupOnInit;

  const NewMobileHomePage({
    super.key,
    this.openPopupOnInit = false,
  });

  @override
  State<NewMobileHomePage> createState() => _MobileMainPageState();
}

class _MobileMainPageState extends State<NewMobileHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<SimpleProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<Map>(
            future: HttpServices().getBalance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                monthlyExpenseLeft = snapshot.data!["monthly_expense_left"].toInt() ?? 0;
                savings = (snapshot.data!["savings"]).toInt() ?? 0;
                variableExpense = (snapshot.data!["variable_expense"]).toInt() ?? 0;
                mutualFundsTotal = (snapshot.data!["mutual_funds_total"]).toInt() ?? 0;
                mutualFundsTotal = (snapshot.data!["mutual_funds_total"]).toInt() ?? 0;
                username = (snapshot.data!["username"]) ?? "Back";
                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Greeting
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            Gap(10.h),

                            // UserName
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AppText(
                                    "Welcome $username",
                                    fontSize: 20.sp,
                                    color: Colors.white,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (context) => const DebitCreditMethod(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.all(15.sp), backgroundColor: primaryColor),
                                    child: Center(
                                        child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    )),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Gap(40.h),

                      // Total Monthly Left
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText("Total Monthly Balance left", color: const Color.fromARGB(255, 156, 156, 156), fontSize: 14.sp, fontWeight: FontWeight.w400),
                            AppText("₹ ${formatIndianSystem(snapshot.data?["monthly_expense_left"])}", color: Colors.white, fontSize: 50.sp, fontWeight: FontWeight.w500),
                          ],
                        ),
                      ),

                      Gap(40.h),

                      // Switcher
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(color: const Color.fromARGB(255, 13, 13, 13), borderRadius: BorderRadius.circular(30.r)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.sp, horizontal: 20.w),
                          child: Column(
                            children: [
                              Expanded(child: SwitcherWithFade(financialData: snapshot.data!)),
                            ],
                          ),
                        ),
                      ))
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
