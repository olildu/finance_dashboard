import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/services/common_services.dart';
import 'package:finance_dashboard/services/http_services.dart';
import 'package:finance_dashboard/widgets/common_widgets/text_widget.dart';
import 'package:finance_dashboard/widgets/desktop_widgets/main_page/bar_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class TransactionsPage extends StatefulWidget {
  final Map financialData;

  const TransactionsPage({
    super.key,
    required this.financialData,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isLoading = true;
  List _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final now = DateTime.now();
    final String currentMonth = months[now.month - 1];
    final String currentYear = now.year.toString();

    try {
      final data = await HttpServices().getTransactions(currentMonth, currentYear);
      List fetchedTransactions = data["transactions"] ?? [];

      fetchedTransactions.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date']);
        DateTime dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _transactions = fetchedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _transactions = [];
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load transactions.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              "Transactions for $month",
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
            CircleAvatar(
              radius: 14.r,
              backgroundColor: const Color.fromARGB(255, 90, 90, 90),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color.fromARGB(255, 254, 254, 254),
                  size: 13,
                ),
                onPressed: () {
                  GoRouter.of(context).push('/transactions');
                },
              ),
            ),
          ],
        ),
        Gap(10.h),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? Center(
                      child: AppText(
                        "No transactions for this month.",
                        color: Colors.white54,
                        fontSize: 14.sp,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final txn = _transactions[index];
                        final bool isDebit = txn["method"] == "debit";

                        final String reasonText = (txn["reason"] == null || txn["reason"].toString().trim().isEmpty) ? "Unnamed Transaction" : txn["reason"];

                        final Color reasonColor = (txn["reason"] == null || txn["reason"].toString().trim().isEmpty) ? Colors.white54 : Colors.white;

                        return Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    reasonText,
                                    color: reasonColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  Gap(4.h),
                                  AppText(
                                    formatDate(txn["date"]),
                                    color: Colors.white54,
                                    fontSize: 11.sp,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AppText(
                                    "${isDebit ? '-' : '+'}₹${txn["amount"]}",
                                    color: isDebit ? Colors.redAccent : Colors.greenAccent,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Gap(4.h),
                                  AppText(
                                    txn["category"],
                                    color: Colors.white54,
                                    fontSize: 11.sp,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
