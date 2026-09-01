import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';

/// CreditBalanceWidget displays the current credit balance
class CreditBalanceWidget extends StatelessWidget {
  const CreditBalanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, _) {
        final balance = creditProvider.balance;
        final isLoading = creditProvider.isLoading;
        final errorMessage = creditProvider.errorMessage;

        if (errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
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
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (balance == null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    const Text('No balance data available'),
                ],
              ),
            ),
          );
        }

        final hasDebt = balance > 0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Balance Card
                Semantics(
                  button: false,
                  label: 'Credit balance information',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: hasDebt
                          ? Border.all(color: Colors.red.withOpacity(0.5))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credit Balance',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.grey[400],
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: hasDebt ? Colors.red[300] : Colors.green[300],
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (hasDebt)
                          Semantics(
                            label: 'Outstanding debt warning',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Outstanding debt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.orange[300],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Semantics(
                            label: 'No outstanding debt',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No outstanding debt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.green[300],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
