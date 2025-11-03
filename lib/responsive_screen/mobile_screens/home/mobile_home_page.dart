import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/providers/data_provider.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/debit_credit_method.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/bar_chart_widget.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/your_portfolio_widget.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/title.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/total_assets_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

class MobileHomePage extends StatefulWidget {
  final bool openPopupOnInit;

  const MobileHomePage({
    super.key,
    this.openPopupOnInit = false,
  });

  @override
  State<MobileHomePage> createState() => _MobileMainPageState();
}

class _MobileMainPageState extends State<MobileHomePage> {
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
                return SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 40.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title("₹ Total monthlyExpenseLeft"),
                          // balanceWidget(snapshot.data!["monthlyExpenseLeft"], snapshot.data!["spent_today"], snapshot.data!["days_left"]),

                          Gap(10.h),

                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                title("Welcome Back\nHello User", size: 20.sp),
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

                          Gap(20.h),

                          totalAssetsWidget(snapshot.data!),

                          Gap(20.h),

                          title("Your Portfolio"),

                          yourPortFolioWidget([monthlyExpenseLeft, savings, variableExpense, mutualFundsTotal]),

                          Gap(20.h),

                          title("Your Expenses"),

                          Gap(10.h),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20.r)),
                            child: BarChartSample1(
                              financialData: snapshot.data!,
                              showTitle: false,
                            ),
                          ),

                          // summaryWidget(context, snapshot.data!["category_totals"], snapshot.data!["total_expense"], snapshot.data!["category_percentages"]),
                        ],
                      ),
                    ),
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
