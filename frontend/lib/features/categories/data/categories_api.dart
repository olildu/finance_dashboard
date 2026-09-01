import 'package:dio/dio.dart';

/// CategoriesApi handles all category-related API calls
class CategoriesApi {
  final Dio dio;

  CategoriesApi(this.dio);

  /// Fetch all categories from the server
  /// Returns a list of category maps containing: code, display_name, envelope
  /// Each envelope contains: name, monthly_amount, account_code
  /// Throws an exception on failure
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await dio.get('/categories');
      final data = response.data;

      // Backend returns {"categories": [...]}
      if (data is Map && data.containsKey('categories')) {
        final categoriesList = data['categories'];
        if (categoriesList is List) {
          return List<Map<String, dynamic>>.from(
            categoriesList.map((item) => Map<String, dynamic>.from(item as Map)),
          );
        }
      }
      // Fallback for list response
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      return [];
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
