import 'package:dio/dio.dart';

/// TransactionsApi handles all transaction-related API calls
class TransactionsApi {
  final Dio dio;

  TransactionsApi(this.dio);

  /// Create a new transaction
  /// [categoryCode] - The category code (e.g., 'food', 'rent')
  /// [amount] - Transaction amount
  /// [reason] - Optional reason for the transaction
  /// [date] - Date of the transaction
  /// Returns the created transaction details
  /// Throws an exception on failure
  Future<Map<String, dynamic>> createTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) async {
    try {
      final response = await dio.post(
        '/transactions',
        data: {
          'category_code': categoryCode,
          'amount': amount,
          'reason': reason,
          'date': date.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to create transaction: ${e.message}');
    }
  }

  /// Fetch all transactions for the current month
  /// Returns a list of transaction maps
  /// Throws an exception on failure
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await dio.get('/transactions');
      final data = response.data;
      // Backend returns TransactionListResponse: {"transactions": [...]}
      if (data is Map && data['transactions'] is List) {
        return List<Map<String, dynamic>>.from(
          (data['transactions'] as List).map((item) => item as Map<String, dynamic>),
        );
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load transactions: ${e.message}');
    }
  }

  /// Delete a transaction by ID
  /// [transactionId] - The ID of the transaction to delete
  /// Returns true on success
  /// Throws an exception on failure
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      await dio.delete('/transactions/$transactionId');
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to delete transaction: ${e.message}');
    }
  }
}
