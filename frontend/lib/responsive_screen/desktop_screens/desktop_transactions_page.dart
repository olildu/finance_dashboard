import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/transactions/mobile_transactions_page.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/transaction_page/detailed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class DesktopTransactionsPage extends StatefulWidget {
  const DesktopTransactionsPage({super.key});

  @override
  State<DesktopTransactionsPage> createState() => _DesktopTransactionsPageState();
}

class _DesktopTransactionsPageState extends State<DesktopTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Padding(
        padding: EdgeInsets.all(15.sp),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: const MobileTransactionPage(),
              ),
            ),
        
            Gap(10.w),

            const DetailedView(),

            Gap(10.w),

            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  color: backgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}