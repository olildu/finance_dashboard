import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/bottom_row_widgets.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/center_row_widgets.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/top_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  bool isDataFetching = true;
  Map financialData = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    financialData = await HttpServices().getBalance();
    setState(() {
      financialData;
      isDataFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<IconData> iconsTop = [Icons.account_balance_wallet_outlined, Icons.account_balance_rounded, Icons.credit_card_rounded, Icons.show_chart_rounded];
    List<IconData> iconsCenter = [Icons.calendar_month_outlined, Icons.savings_outlined];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: isDataFetching 
      ? const Center(child: CircularProgressIndicator())
      :  Padding(
        padding: EdgeInsets.all(15.sp),
        child: Column(
          children: [
            // Top Items
            topRow(context, iconsTop, financialData),

            // Center Items
            centerRow(context, iconsCenter, financialData),

            // Bottom Items
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    Expanded(
                      child: BottomItems(
                        data: financialData["mutual_funds_performance"]?["large_cap"] ?? 0,
                        index: 0
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: BottomItems(
                        data: financialData["mutual_funds_performance"]?["mid_cap"] ?? 0, 
                        index: 1
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: BottomItems(
                        data: financialData["mutual_funds_performance"]?["total"] ?? 0, 
                        index: 2
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
