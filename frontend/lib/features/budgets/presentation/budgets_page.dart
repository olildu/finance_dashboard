import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/budgets/presentation/category_pace_card.dart';

/// BudgetsPage displays the budget dashboard with all categories
class BudgetsPage extends StatefulWidget {
  const BudgetsPage({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Budget Overview'),
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
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Budgets',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show empty state if no categories
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wallet_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Budgets Available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your budgets to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ],
              ),
            );
          }

          // Display the list of budget categories
          return RefreshIndicator(
            onRefresh: () => budgetsProvider.load(forceRefresh: true),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryPaceCard(status: category);
              },
            ),
          );
        },
      ),
    );
  }
}
