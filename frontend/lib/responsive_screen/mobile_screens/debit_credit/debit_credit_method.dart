import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_debit_credit_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_monthly_expense_catergories_page.dart';
import 'package:finance_dashboard/responsive_screen/mobile_screens/debit_credit/mobile_mutual_fund_name_page.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/main_page/title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

List <IconData> icons = [
  Icons.calendar_month_rounded,
  Icons.currency_rupee_rounded,
  Icons.savings_rounded,
  Icons.auto_graph_rounded
];

List <String> cardText = [
  "Monthly Expense",
  "Variable Expense",
  "Savings Expense",
  "Mutual Funds"
];

class DebitCreditMethod extends StatefulWidget {
  const DebitCreditMethod({super.key});

  @override
  State<DebitCreditMethod> createState() => _DebitCreditMethodState();
}

class _DebitCreditMethodState extends State<DebitCreditMethod> {
  int cardIndex = -1;
  bool canClick = true;
  bool isDebit = true;

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

        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),  
            child: Row(
              children: [
               GestureDetector(
                onTap: () {
                  setState(() {
                    isDebit = !isDebit;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  width: 100.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: ClipRRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0, 1), 
                            end: Offset.zero,
                          ).animate(animation);
                      
                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          key: ValueKey<bool>(isDebit),
                          isDebit ? "Debit" : "Credit",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ],
            )
          )
        ],
      ),


      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
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

          if (index == 0) {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => MobileMonthlyExpenseCatergoriesPage(
                  index: index,
                  isDebit: isDebit,
                ),
              ),
            );
          }
          else if (index == 3){
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => MobileMutualFundNamePage(
                  index: index,
                  isDebit: isDebit,
                ),
              ),
            );
          }
          
          else {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => MobileDebitCreditPage(
                  title: cardText[index],
                  index: index,
                  isDebit: isDebit,
                ),
              ),
            );
          }

        });


        setState(() {
          cardIndex = -1;
          canClick = true;
        });

      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: 135.h,
        height: 145.h, 
        padding: EdgeInsets.symmetric(vertical: 30.h),
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
            Icon(icons[index], color: Colors.white, size: 55,),
                
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

