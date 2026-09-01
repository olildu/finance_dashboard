import 'package:dio/dio.dart';

/// AccountsApi handles all account-related API calls
class AccountsApi {
  final Dio dio;

  AccountsApi(this.dio);

  /// Fetch all accounts from the server
  /// Returns a list of account maps containing: id, name, balance, expected_balance
  /// Throws an exception on failure
  Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final response = await dio.get('/accounts');
      final data = response.data;

      // Ensure response is a list
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } else if (data is Map) {
        // In case the API wraps the list in a key
        return [];
      }
      return [];
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// Fetch month-end check data from the server
  /// Returns a map containing: hdfc_reserve, total_net_worth, accounts
  /// Throws an exception on failure
  Future<Map<String, dynamic>> getMonthEndCheck() async {
    try {
      final response = await dio.get('/accounts/month-end-check');
      final data = response.data;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// Handle DioException and convert to meaningful error messages
  void _handleDioException(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data is Map
          ? e.response!.data['message'] ?? 'An error occurred'
          : 'An error occurred';
      throw Exception('$message (HTTP $statusCode)');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception(
          'Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Server took too long to respond. Please try again.');
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw Exception('Request timeout. Please try again.');
    } else {
      throw Exception('Network error: ${e.message ?? "Unknown error"}');
    }
  }
}
