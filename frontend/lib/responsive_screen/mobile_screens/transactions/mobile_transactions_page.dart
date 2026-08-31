import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/transaction_page/appbar.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/transaction_page/month_transaction_number_widget.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/transaction_page/transactions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MobileTransactionPage extends StatefulWidget {
  const MobileTransactionPage({super.key});

  @override
  State<MobileTransactionPage> createState() => _MobileTransactionPageState();
}

class _MobileTransactionPageState extends State<MobileTransactionPage> {
  int reuquiredIndex = 0;
  String transactionDropddown = "All";
  
  void changeTransactionTimeLine(int value, String transactionDropdown){
    setState(() {
      reuquiredIndex = value;
      transactionDropddown = transactionDropdown;
      month = month;
    });
  }

  void changeMonth(String value) {
    setState(() {
      month = value;
    });
  }

  void cardChange(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var date = DateTime.now();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar(context),

      body: FutureBuilder<Map>(
        future: HttpServices().getTransactions(months[date.month - 1], date.year.toString()),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 30.h),
              child: Column(
                children: [
                  monthTransactionNumber(snapshot.data!["transactions"].length, transactionDropddown, month, changeTransactionTimeLine, changeMonth),
                  TransactionsCard(transactions: snapshot.data!["transactions"], requiredIndex: reuquiredIndex, cardChange: cardChange)
                ],
              ),
            );
          }
        }
      ),
    );
  } 
}
