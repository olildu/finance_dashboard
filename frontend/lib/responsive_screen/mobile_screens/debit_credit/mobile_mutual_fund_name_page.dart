import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_debit_credit_page.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

List <String> images = [
  "assets/MOTILAL.png",
  "assets/ICICI.jpg",
];

List <String> cardText = [
  "Motilal Oswal Midcap Fund",
  "ICICI Prudential Bluechip Fund",
];

class MobileMutualFundNamePage extends StatefulWidget {
  final int index;
  final bool isDebit;
  const MobileMutualFundNamePage({
    super.key, 
    required this.index,
    required this.isDebit
  });

  @override
  State<MobileMutualFundNamePage> createState() => _DebitCreditMethodState();
}

class _DebitCreditMethodState extends State<MobileMutualFundNamePage> {
  int cardIndex = -1;
  bool canClick = true;

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
              Navigator.of(context).pop();
            }, 
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: primaryColor
            ),
            child: Center(child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17.sp,))
          ),
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
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
        margin: EdgeInsets.all(10.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: cardIndex == index
            ? Colors.yellow
            : Colors.transparent  
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [ 
            Image.asset(
              images[index],
              width: 50,
              height: 50,
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

}

