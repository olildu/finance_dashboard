import 'dart:developer';

import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_debit_credit_page.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

List<IconData> icons = [
  Icons.restaurant_rounded,
  Icons.checkroom_rounded,
  Icons.flight_rounded,
  Icons.shopping_bag_rounded,
  Icons.payments_rounded,
  Icons.auto_graph_rounded,
];

List<String> cardText = ["Food & Drinks", "Laundry", "Travel", "Shopping", "Bill", "Others"];

class MobileMonthlyExpenseCatergoriesPage extends StatefulWidget {
  final int index;
  final bool isDebit;
  final int? amount;
  const MobileMonthlyExpenseCatergoriesPage({
    super.key,
    required this.index,
    required this.isDebit,
    this.amount,
  });

  @override
  State<MobileMonthlyExpenseCatergoriesPage> createState() => _DebitCreditMethodState();
}

class _DebitCreditMethodState extends State<MobileMonthlyExpenseCatergoriesPage> {
  int cardIndex = -1;
  bool canClick = true;
  List choices = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.r),
          child: ElevatedButton(
              onPressed: () {
                GoRouter.of(context).push('/');
              },
              style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero, backgroundColor: primaryColor),
              child: Center(
                  child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17.sp,
              ))),
        ),
        title: title("Choose Catergory"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.h),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                catergoryTile(0),
                catergoryTile(1),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                catergoryTile(2),
                catergoryTile(3),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                catergoryTile(4),
                catergoryTile(5),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget catergoryTile(int index) {
    return GestureDetector(
      onTap: () async {
        if (!canClick) {
          return;
        }
        setState(() {
          cardIndex = index;
          canClick = false;
        });

        await Future.delayed(const Duration(milliseconds: 500)).then((_) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => MobileDebitCreditPage(
                title: cardText[index],
                index: widget.index,
                isDebit: widget.isDebit,
                amount: widget.amount,
                choices: choices,
              ),
            ),
          );
        });

        setState(() {
          cardIndex = -1;
          canClick = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: 170.h,
        height: 170.h,
        padding: EdgeInsets.symmetric(vertical: 30.h),
        margin: EdgeInsets.all(10.h),
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: cardIndex == index ? Colors.yellow : Colors.transparent)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icons[index],
              color: Colors.white,
              size: 55,
            ),
            Gap(15.h),
            Text(
              cardText[index],
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    getChoices();
    super.initState();
  }

  Future<void> getChoices() async {
    if (widget.amount != null) {
      List results = await HttpServices().getChoices(widget.amount.toString());
      choices = results;
      log(results.toString(), name: "Choices");
    }
  }
}
