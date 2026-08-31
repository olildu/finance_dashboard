import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/features/budgets/presentation/category_pace_card.dart';
import 'package:finance_dashboard/features/credit/presentation/credit_balance_widget.dart';
import 'package:finance_dashboard/core/theme/colors.dart';

/// HomePage displays the complete dashboard with accounts, budgets, credit, and transactions
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          return Stack(
            children: [
              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder text
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'TODO: Dashboard home screen',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),

                      // Month-End Check Section
                      if (dashboardProvider.monthEndCheck != null)
                        _buildMonthEndCheckSection(
                          context,
                          dashboardProvider.monthEndCheck!,
                        ),

                      // Credit Balance Section
                      if (dashboardProvider.creditBalance != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Credit Balance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.grey[400],
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${dashboardProvider.creditBalance.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: dashboardProvider
                                                    .creditBalance >
                                                0
                                                ? Colors.red[300]
                                                : Colors.green[300],
                                          ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  dashboardProvider.creditBalance > 0
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_rounded,
                                  color: dashboardProvider.creditBalance > 0
                                      ? Colors.orange
                                      : Colors.green,
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Budget Statuses Section
                      if (dashboardProvider.budgetStatuses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Text(
                                'Budget Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            ...dashboardProvider.budgetStatuses
                                .map((status) => CategoryPaceCard(status: status)),
                          ],
                        ),

                      // Recent Transactions Section
                      if (dashboardProvider.transactions.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Text(
                                'Recent Transactions',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            ...dashboardProvider.transactions
                                .take(5)
                                .map((transaction) => _buildTransactionTile(
                                      context,
                                      transaction,
                                    )),
                          ],
                        ),

                      // Error message if present
                      if (dashboardProvider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[300],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dashboardProvider.errorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.red[300],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (dashboardProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthEndCheckSection(
    BuildContext context,
    Map<String, dynamic> monthEndData,
  ) {
    final hdfc = monthEndData['hdfc_reserve'] as num? ?? 0;
    final netWorth = monthEndData['total_net_worth'] as num? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month-End Check',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HDFC Reserve',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${hdfc.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[100],
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Net Worth',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${netWorth.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[300],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final amount = transaction['amount'] as num? ?? 0;
    final category = transaction['category'] ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[200],
                      ),
                ),
              ],
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[100],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
