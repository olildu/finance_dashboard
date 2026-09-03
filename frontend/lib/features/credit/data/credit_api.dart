import 'package:dio/dio.dart';

/// CreditApi handles all credit-related API calls
class CreditApi {
  final Dio dio;

  CreditApi(this.dio);

  /// Fetch the current credit balance from the server
  /// Returns a map containing: balance
  /// Throws an exception on failure
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await dio.get('credit/balance');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch the credit ledger history from the server
  /// Returns a map containing: entries (list of ledger entries)
  /// Each entry contains: id, month, category_code, amount, entry_type, created_at
  /// Throws an exception on failure
  Future<Map<String, dynamic>> getHistory() async {
    try {
      final response = await dio.get('credit/history');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
