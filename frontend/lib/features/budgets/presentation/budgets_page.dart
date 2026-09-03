import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/budgets/presentation/category_pace_card.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/widgets/responsive_layout.dart';

/// BudgetsPage displays the budget dashboard with all categories
class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    // Load budget data when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Budget Overview'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BudgetsProvider>(
        builder: (context, budgetsProvider, _) {
          final categories = budgetsProvider.categories;
          final isLoading = budgetsProvider.isLoading;
          final errorMessage = budgetsProvider.errorMessage;

          // Show error message if any
          if (errorMessage != null && categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: errorColor, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Budgets',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedTextColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      budgetsProvider.load(forceRefresh: true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show loading indicator
          if (isLoading && categories.isEmpty) {
            return Center(child: CircularProgressIndicator(color: highlightColor));
          }

          // Show empty state if no categories
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallet_outlined, size: 48, color: mutedTextColor),
                  const SizedBox(height: 16),
                  const Text(
                    'No Budgets Available',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your budgets to get started',
                    style: TextStyle(color: mutedTextColor),
                  ),
                ],
              ),
            );
          }

          // Display the list of budget categories
          return RefreshIndicator(
            onRefresh: () => budgetsProvider.load(forceRefresh: true),
            backgroundColor: primaryColor,
            color: highlightColor,
            child: ResponsiveLayout(
              mobile: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) => CategoryPaceCard(status: categories[index]),
              ),
              desktop: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) => CategoryPaceCard(status: categories[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
