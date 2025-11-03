import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/providers/transaction_card_provider.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/mobile_widgets/transaction_page/method_category_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TransactionsCard extends StatefulWidget {
  final List transactions;
  final int requiredIndex;
  final VoidCallback cardChange;

  const TransactionsCard({
    required this.transactions,
    required this.requiredIndex,
    required this.cardChange,
    super.key,
  });

  @override
  TransactionsCardState createState() => TransactionsCardState();
}

class TransactionsCardState extends State<TransactionsCard> {
  late List sortedTransactions;
  int currentIndex = -1;

  @override
  void initState() {
    super.initState();
    sortedTransactions = widget.transactions;
    sortedTransactions.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });
    sortedTransactions = DataPaser().parseData(sortedTransactions);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: sortedTransactions[widget.requiredIndex].length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                currentIndex = index;
                Provider.of<TransactionCardProvider>(navigatorkey.currentContext!, listen: false).changeCard(sortedTransactions[widget.requiredIndex][index]);
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  children: [
                    Container(
                      width: 88,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Column(
                        children: [
                          SlidableAction(
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(30.r),
                            flex: 1,
                            onPressed: (e) async {
                              var stuff = sortedTransactions[widget.requiredIndex][index];
                              await HttpServices().deleteTransaction(
                                stuff["id"].toString(),
                                stuff["amount"].toString(),
                                stuff["bracket"].toString(),
                                stuff["m_id"].toString(),
                                stuff["method"].toString(),
                              );
                              setState(() {
                                sortedTransactions[widget.requiredIndex].removeAt(index);
                              });
                              widget.cardChange();
                            },
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 100.h,
                  margin: EdgeInsets.symmetric(vertical: 5.h),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    border: Border.all(
                      color: currentIndex == index ? const Color.fromARGB(255, 255, 242, 124) : const Color.fromARGB(255, 70, 70, 70),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10.h, bottom: 0, left: 10.w),
                            child: Text(
                              sortedTransactions[widget.requiredIndex][index]["reason"].toString().trim().isEmpty ? "No reason provided" : sortedTransactions[widget.requiredIndex][index]["reason"],
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.h, bottom: 0, right: 10.w),
                            child: Text(
                              formatDate(sortedTransactions[widget.requiredIndex][index]["date"]),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 197, 197, 197),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Color.fromARGB(255, 82, 82, 82),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sortedTransactions[widget.requiredIndex][index]["method"] == "debit"
                                    ? "-${formatIndianSystem(sortedTransactions[widget.requiredIndex][index]["amount"])} ₹"
                                    : "${formatIndianSystem(sortedTransactions[widget.requiredIndex][index]["amount"])} ₹",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                              methodCategoryClassWidget(
                                sortedTransactions[widget.requiredIndex][index]["method"],
                                sortedTransactions[widget.requiredIndex][index]["category"],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DataPaser {
  List variableExpense = [];
  List savings = [];
  List monthlyExpense = [];
  List all = [];

  List<List> parseData(List data) {
    for (var x in data) {
      if (x["bracket"] == "monthly-transactions") {
        monthlyExpense.add(x);
      }
      if (x["bracket"] == "savings-expense-transactions") {
        savings.add(x);
      }
      if (x["bracket"] == "variable-expense-transactions") {
        variableExpense.add(x);
      }
      all.add(x);
    }
    return [all, monthlyExpense, variableExpense, savings];
  }
}
