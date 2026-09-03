import 'package:dio/dio.dart';

/// BudgetsApi handles all budget-related API calls
class BudgetsApi {
  final Dio dio;

  BudgetsApi(this.dio);

  /// Fetch the budget status for all categories in the current month from the server
  /// Returns a map containing: categories (list of category status entries)
  /// Each category entry contains: category_code, display_name, budget, spent, remaining,
  /// days_left, allowance_per_day, burn_rate_per_day, projected_runout_date
  /// Throws an exception on failure
  Future<Map<String, dynamic>> getStatus() async {
    final response = await dio.get('budgets/status');
    return response.data as Map<String, dynamic>;
  }
}
