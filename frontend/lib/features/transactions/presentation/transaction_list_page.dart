import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';

/// Page for listing transactions
class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  @override
  void initState() {
    super.initState();
    // Load transactions when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().load();
    });
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    final double? doubleAmount = (amount as num?)?.toDouble();
    if (doubleAmount == null) return '0.00';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(doubleAmount);
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  void _deleteTransaction(int transactionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: const Text(
            'Delete Transaction',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this transaction?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await context.read<TransactionsProvider>().deleteTransaction(transactionId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TransactionsProvider>().load();
            },
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Consumer<TransactionsProvider>(
        builder: (context, transactionsProvider, child) {
          // Show loading indicator
          if (transactionsProvider.isLoading && transactionsProvider.transactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message
          if (transactionsProvider.errorMessage != null && transactionsProvider.transactions.isEmpty) {
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
                      transactionsProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<TransactionsProvider>().load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show empty state
          if (transactionsProvider.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first transaction to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: () => context.read<TransactionsProvider>().load(),
            backgroundColor: primaryColor,
            color: Colors.blue,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: transactionsProvider.transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactionsProvider.transactions[index];
                final isOverage = transaction['is_overage'] as bool? ?? false;
                final categoryCode = transaction['category_code'] as String? ?? 'Unknown';
                final amount = transaction['amount'] as dynamic;
                final reason = transaction['reason'] as String?;
                final date = transaction['date'] as String? ?? '';
                final id = transaction['id'] as int?;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isOverage ? Colors.red : Colors.white30,
                      width: isOverage ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: isOverage
                        ? Colors.red.withOpacity(0.15)
                        : primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isOverage)
                          const Tooltip(
                            message: 'Over budget',
                            child: Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                          )
                        else
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.blue,
                            size: 24,
                          ),
                      ],
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                categoryCode.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\$${_formatCurrency(amount)}',
                              style: TextStyle(
                                color: isOverage ? Colors.red : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (reason != null && reason.isNotEmpty)
                          Text(
                            reason,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        if (isOverage)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OVERAGE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.white70,
                      onPressed: () {
                        if (id != null) {
                          _deleteTransaction(id);
                        }
                      },
                    ),
                    onLongPress: () {
                      if (id != null) {
                        _deleteTransaction(id);
                      }
                    },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
