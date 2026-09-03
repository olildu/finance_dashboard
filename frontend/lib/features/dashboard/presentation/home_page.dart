import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/features/budgets/presentation/category_pace_card.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';
import 'package:finance_dashboard/core/theme/text_styles.dart';
import 'package:finance_dashboard/core/widgets/responsive_layout.dart';

/// HomePage displays the complete dashboard with accounts, budgets, credit, and transactions
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Trigger the composed load once the widget mounts — without this the
    // dashboard renders with no data at all, since DashboardProvider only
    // reflects its sub-providers' state once something has actually called
    // load() on them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().load();
      }
    });
  }

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '') ?? 0.0;
    return NumberFormat('#,##0.00', 'en_US').format(num);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, _) {
            return Stack(
              children: [
                ResponsiveLayout(
                  mobile: _buildMobile(context, dashboardProvider),
                  desktop: _buildDesktop(context, dashboardProvider),
                ),
                if (dashboardProvider.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(child: CircularProgressIndicator(color: highlightColor)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile layout
  // ---------------------------------------------------------------------

  Widget _buildMobile(BuildContext context, DashboardProvider dashboardProvider) {
    final netWorth = dashboardProvider.monthEndCheck?['total_net_worth'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/transactions/new'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Total Net Worth', style: AppTextStyles.bodyMuted),
        const SizedBox(height: 8),
        Text('₹${_formatCurrency(netWorth)}', style: AppTextStyles.balanceDisplay),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusHero)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TabBar(
                      indicatorColor: highlightColor,
                      labelColor: highlightColor,
                      unselectedLabelColor: mutedTextColor,
                      tabs: const [Tab(text: 'Overview'), Tab(text: 'Recent')],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOverviewTab(context, dashboardProvider),
                        _buildRecentTab(context, dashboardProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (dashboardProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildErrorBanner(dashboardProvider.errorMessage!),
          ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context, DashboardProvider dashboardProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dashboardProvider.creditBalance != null) _buildCreditCard(dashboardProvider),
        if (dashboardProvider.budgetStatuses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Budget Status', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          ...dashboardProvider.budgetStatuses.map((status) => CategoryPaceCard(status: status)),
        ],
      ],
    );
  }

  Widget _buildRecentTab(BuildContext context, DashboardProvider dashboardProvider) {
    if (dashboardProvider.transactions.isEmpty) {
      return Center(child: Text('No transactions yet', style: AppTextStyles.bodyMuted));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dashboardProvider.transactions.take(10).length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildTransactionTile(context, dashboardProvider.transactions[index]),
    );
  }

  // ---------------------------------------------------------------------
  // Desktop layout
  // ---------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context, DashboardProvider dashboardProvider) {
    final hdfc = dashboardProvider.monthEndCheck?['hdfc_reserve'];
    final netWorth = dashboardProvider.monthEndCheck?['total_net_worth'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dashboardProvider.errorMessage != null) ...[
            _buildErrorBanner(dashboardProvider.errorMessage!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _statCard('Total Net Worth', '₹${_formatCurrency(netWorth)}', Icons.trending_up_rounded),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard('HDFC Reserve', '₹${_formatCurrency(hdfc)}', Icons.account_balance_rounded),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Credit Balance',
                  '₹${_formatCurrency(dashboardProvider.creditBalance)}',
                  (dashboardProvider.creditBalance ?? 0) > 0
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  valueColor: (dashboardProvider.creditBalance ?? 0) > 0 ? errorColor : successColor,
                ),
              ),
            ],
          ),
          if (dashboardProvider.budgetStatuses.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Budget Status', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: dashboardProvider.budgetStatuses
                  .map((status) => CategoryPaceCard(status: status))
                  .toList(),
            ),
          ],
          if (dashboardProvider.transactions.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Recent Transactions', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(radiusPanel),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: dashboardProvider.transactions
                    .take(6)
                    .map((t) => _buildTransactionTile(context, t))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(radiusHero)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: highlightColor, size: 28),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.cardNumber.copyWith(fontSize: 26, color: valueColor ?? Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared bits
  // ---------------------------------------------------------------------

  Widget _buildCreditCard(DashboardProvider dashboardProvider) {
    final balance = dashboardProvider.creditBalance;
    final isOwed = (balance ?? 0) > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(radiusCard)),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Credit Balance', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 8),
              Text(
                '₹${_formatCurrency(balance)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isOwed ? errorColor : successColor,
                ),
              ),
            ],
          ),
          Icon(
            isOwed ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: isOwed ? errorColor : successColor,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as num? ?? 0;
    final category = transaction['category_code'] ?? transaction['category'] ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(radiusChip)),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category, style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text(
              '₹${_formatCurrency(amount)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusInput),
        border: Border.all(color: errorColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: errorColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
