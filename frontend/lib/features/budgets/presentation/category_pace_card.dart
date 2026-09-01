import 'package:flutter/material.dart';
import 'package:finance_dashboard/core/theme/colors.dart';

/// CategoryPaceCard displays budget pace information for a single category
class CategoryPaceCard extends StatelessWidget {
  final Map<String, dynamic> status;

  const CategoryPaceCard({
    Key? key,
    required this.status,
  }) : super(key: key);

  String _formatCurrency(dynamic value) {
    if (value == null) return '\$0.00';
    final num = double.tryParse(value.toString()) ?? 0.0;
    return '\$${num.toStringAsFixed(2)}';
  }

  String _formatMetric(dynamic value) {
    if (value == null) return '0.00';
    final num = double.tryParse(value.toString()) ?? 0.0;
    return num.toStringAsFixed(2);
  }

  double _getProgressValue() {
    final budget = double.tryParse(status['budget'].toString()) ?? 0.0;
    final spent = double.tryParse(status['spent'].toString()) ?? 0.0;
    if (budget <= 0) return 0.0;
    return (spent / budget).clamp(0.0, 1.0);
  }

  Color _getProgressColor(double progress) {
    if (progress > 1.0) {
      return Colors.red[400] ?? Colors.red;
    } else if (progress > 0.75) {
      return Colors.orange[400] ?? Colors.orange;
    } else if (progress > 0.5) {
      return Colors.yellow[600] ?? Colors.yellow;
    }
    return Colors.green[400] ?? Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = status['display_name'] ?? 'Unknown Category';
    final budget = _formatCurrency(status['budget']);
    final spent = _formatCurrency(status['spent']);
    final remaining = _formatCurrency(status['remaining']);
    final daysLeft = status['days_left'] ?? 0;
    final allowancePerDay = _formatMetric(status['allowance_per_day']);
    final burnRatePerDay = _formatMetric(status['burn_rate_per_day']);
    final projectedRunoutDate = status['projected_runout_date'] as String?;

    final progress = _getProgressValue();
    final progressColor = _getProgressColor(progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: progress > 1.0 ? Colors.red.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category name
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),

            // Budget progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      'Spent:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                    Text(
                      '$spent / $budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[200],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8.0,
                    backgroundColor: secondaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Remaining budget
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Text(
                  'Remaining:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                Text(
                  remaining,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: progress > 1.0 ? Colors.red[300] : Colors.green[300],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pace metrics - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 350;

                if (isSmallScreen) {
                  // Stack vertically on small screens
                  return Column(
                    children: [
                      _MetricTile(
                        label: 'Allowance/Day',
                        value: allowancePerDay,
                        context: context,
                      ),
                      const SizedBox(height: 8),
                      _MetricTile(
                        label: 'Burn Rate/Day',
                        value: burnRatePerDay,
                        context: context,
                      ),
                      const SizedBox(height: 8),
                      _MetricTile(
                        label: 'Days Left',
                        value: daysLeft.toString(),
                        context: context,
                      ),
                    ],
                  );
                } else {
                  // Display horizontally on larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Allowance/Day',
                          value: allowancePerDay,
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Burn Rate/Day',
                          value: burnRatePerDay,
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Days Left',
                          value: daysLeft.toString(),
                          context: context,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            // Projected runout date if available
            if (projectedRunoutDate != null)
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red[300],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'May runout on $projectedRunoutDate',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.red[300],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[400],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[100],
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
