import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';
import 'package:finance_dashboard/core/widgets/responsive_layout.dart';

/// Page for listing transactions, styled after the app's reference design:
/// a search header, swipeable rows with category/account chips, and a
/// two-pane desktop layout showing row list + selected transaction detail.
class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().load();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> _filteredTransactions(List<Map<String, dynamic>> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    return transactions.where((transaction) {
      final reason = (transaction['reason'] as String? ?? '').toLowerCase();
      final categoryCode = (transaction['category_code'] as String? ?? '').toLowerCase();
      return reason.contains(_searchQuery) || categoryCode.contains(_searchQuery);
    }).toList();
  }

  void _deleteTransaction(int transactionId) async {
    try {
      await context.read<TransactionsProvider>().deleteTransaction(transactionId);
      if (mounted) {
        setState(() {
          if (_selectedTransaction?['id'] == transactionId) {
            _selectedTransaction = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
        // Budget/credit figures are computed server-side and DashboardProvider
        // doesn't observe its child providers' notifyListeners() calls, so a
        // deletion needs an explicit reload to reflect on budget bars/balance.
        context.read<DashboardProvider>().load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<TransactionsProvider>(
          builder: (context, transactionsProvider, child) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody(context, transactionsProvider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Transactions',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.read<TransactionsProvider>().load(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: Icon(Icons.refresh_rounded, color: mutedTextColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(radiusCard),
              border: Border.all(color: borderColorLight),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search transactions',
                hintStyle: TextStyle(color: mutedTextColor),
                prefixIcon: Icon(Icons.search_rounded, color: mutedTextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionsProvider transactionsProvider) {
    if (transactionsProvider.isLoading && transactionsProvider.transactions.isEmpty) {
      return Center(child: CircularProgressIndicator(color: highlightColor));
    }

    if (transactionsProvider.errorMessage != null && transactionsProvider.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),
              Text(
                transactionsProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedTextColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<TransactionsProvider>().load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final transactions = _filteredTransactions(transactionsProvider.transactions);

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: mutedTextColor),
              const SizedBox(height: 16),
              const Text(
                'No transactions yet',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first transaction to get started',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedTextColor, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: () => context.read<TransactionsProvider>().load(),
      backgroundColor: primaryColor,
      color: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildRow(transactions[index]),
      ),
    );

    return ResponsiveLayout(
      mobile: list,
      desktop: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusPanel),
                child: list,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusPanel),
                child: _buildDetailPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> transaction) {
    final isOverage = transaction['is_overage'] as bool? ?? false;
    final categoryCode = transaction['category_code'] as String? ?? 'Unknown';
    final fundingAccountCode = transaction['funding_account_code'] as String?;
    final amount = transaction['amount'];
    final reason = transaction['reason'] as String?;
    final date = transaction['date'] as String? ?? '';
    final id = transaction['id'] as int?;
    final isSelected = _selectedTransaction?['id'] == id;

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: isSelected ? highlightColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (reason == null || reason.isEmpty) ? categoryCode.toUpperCase() : reason,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(date),
                style: TextStyle(color: mutedTextColorLight, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: borderColorLight.withOpacity(0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${isOverage ? '-' : ''}₹${_formatCurrency(amount)}',
                style: TextStyle(
                  color: isOverage ? errorColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _buildChip(Icons.category_rounded, categoryCode),
              if (fundingAccountCode != null) ...[
                const SizedBox(width: 6),
                _buildChip(Icons.account_balance_wallet_rounded, fundingAccountCode),
              ],
            ],
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedTransaction = transaction),
      child: Slidable(
        key: ValueKey(id ?? transaction.hashCode),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) {
                if (id != null) _deleteTransaction(id);
              },
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(radiusCard),
            ),
          ],
        ),
        child: row,
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBackgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final transaction = _selectedTransaction;
    if (transaction == null) {
      return Container(
        color: primaryColor,
        alignment: Alignment.center,
        child: Text('Select a transaction', style: TextStyle(color: mutedTextColor)),
      );
    }

    final amount = transaction['amount'];
    final categoryCode = transaction['category_code'] as String? ?? 'Unknown';
    final fundingAccountCode = transaction['funding_account_code'] as String?;
    final reason = transaction['reason'] as String?;
    final date = transaction['date'] as String? ?? '';
    final isOverage = transaction['is_overage'] as bool? ?? false;
    final type = transaction['type'] as String?;

    return Container(
      color: primaryColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₹${_formatCurrency(amount)}',
              style: TextStyle(
                color: isOverage ? errorColor : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text(_formatDate(date), style: TextStyle(color: mutedTextColor)),
          const SizedBox(height: 20),
          if (reason != null && reason.isNotEmpty) ...[
            _detailRow('Note', reason),
            const SizedBox(height: 12),
          ],
          _detailRow('Category', categoryCode),
          const SizedBox(height: 12),
          if (fundingAccountCode != null) ...[
            _detailRow('Account', fundingAccountCode),
            const SizedBox(height: 12),
          ],
          if (type != null) ...[
            _detailRow('Type', type),
            const SizedBox(height: 12),
          ],
          if (isOverage) _buildChip(Icons.warning_rounded, 'OVERAGE'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: mutedTextColor, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
