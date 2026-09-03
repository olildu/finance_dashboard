import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';
import 'package:finance_dashboard/core/theme/text_styles.dart';
import 'package:finance_dashboard/core/widgets/responsive_layout.dart';

/// CreditBalanceWidget displays the current credit balance as a hero card,
/// matching the dashboard's stat-card visual language.
class CreditBalanceWidget extends StatelessWidget {
  const CreditBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Consumer<CreditProvider>(
        builder: (context, creditProvider, _) {
          final balance = creditProvider.balance;
          final isLoading = creditProvider.isLoading;
          final errorMessage = creditProvider.errorMessage;

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: errorColor, size: 48),
                    const SizedBox(height: 16),
                    const Text('Error', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                  ],
                ),
              ),
            );
          }

          if (balance == null) {
            return Center(
              child: isLoading
                  ? CircularProgressIndicator(color: highlightColor)
                  : Text('No balance data available', style: TextStyle(color: mutedTextColor)),
            );
          }

          final hasDebt = balance > 0;

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ResponsiveLayout.isDesktop(context) ? 480 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Semantics(
                    label: 'Credit balance information',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(radiusHero),
                        border: hasDebt ? Border.all(color: errorColor.withOpacity(0.5)) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Credit Balance', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 12),
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: AppTextStyles.cardNumber.copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: hasDebt ? errorColor : successColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: hasDebt ? 'Outstanding debt warning' : 'No outstanding debt',
                            child: Row(
                              children: [
                                Icon(
                                  hasDebt ? Icons.warning_rounded : Icons.check_circle_rounded,
                                  color: hasDebt ? Colors.orange : successColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasDebt ? 'Outstanding debt' : 'No outstanding debt',
                                    style: TextStyle(
                                      color: hasDebt ? Colors.orange[300] : successColor,
                                      fontSize: 13,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
