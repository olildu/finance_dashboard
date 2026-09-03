import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';

/// MonthEndCheckPage displays a summary of accounts and month-end check data
class MonthEndCheckPage extends StatefulWidget {
  const MonthEndCheckPage({Key? key}) : super(key: key);

  @override
  State<MonthEndCheckPage> createState() => _MonthEndCheckPageState();
}

class _MonthEndCheckPageState extends State<MonthEndCheckPage> {
  @override
  void initState() {
    super.initState();
    // Load accounts data when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().load();
    });
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    final double? doubleAmount = (amount as num?)?.toDouble();
    if (doubleAmount == null) return '0.00';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(doubleAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Month End Check'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AccountsProvider>().load();
            },
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Consumer<AccountsProvider>(
        builder: (context, accountsProvider, child) {
          // Show loading indicator
          if (accountsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: highlightColor),
            );
          }

          // Show error message
          if (accountsProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      accountsProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AccountsProvider>().load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show main content
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HDFC Reserve Card
                if (accountsProvider.monthEndCheck != null)
                  _buildSummaryCard(
                    title: 'HDFC Reserve',
                    amount: accountsProvider.monthEndCheck!['hdfc_reserve'],
                    color: Colors.blue,
                  ),
                const SizedBox(height: 16),

                // Total Net Worth Card
                if (accountsProvider.monthEndCheck != null)
                  _buildSummaryCard(
                    title: 'Total Net Worth',
                    amount: accountsProvider.monthEndCheck!['total_net_worth'],
                    color: Colors.green,
                  ),
                const SizedBox(height: 24),

                // Accounts List Title
                Text(
                  'Account Balances',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),

                // Accounts List - render ICICI, SBI, SLICE from month-end check
                if (accountsProvider.monthEndCheck == null ||
                    (accountsProvider.monthEndCheck!['ICICI'] == null &&
                        accountsProvider.monthEndCheck!['SBI'] == null &&
                        accountsProvider.monthEndCheck!['SLICE'] == null))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(radiusCard),
                    ),
                    child: const Center(
                      child: Text(
                        'No account balances available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      if (accountsProvider.monthEndCheck!['ICICI'] != null)
                        _buildAccountCard(
                          name: 'ICICI',
                          balance: accountsProvider.monthEndCheck!['ICICI']['expected_balance'],
                        ),
                      if (accountsProvider.monthEndCheck!['SBI'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildAccountCard(
                            name: 'SBI',
                            balance: accountsProvider.monthEndCheck!['SBI']['expected_balance'],
                          ),
                        ),
                      if (accountsProvider.monthEndCheck!['SLICE'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildAccountCard(
                            name: 'SLICE',
                            balance: accountsProvider.monthEndCheck!['SLICE']['expected_balance'],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required dynamic amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required String name,
    required dynamic balance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatCurrency(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
