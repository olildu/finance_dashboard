import 'package:dio/dio.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/providers/data_provider.dart';
import 'package:finance_dashboard/services/token_services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HttpServices {
  late Dio _dio;
  final TokenManager _tokenManager = TokenManager();

  // static const String endpoint = "/";
  static const String endpoint = "http://127.0.0.1:9000/";

  HttpServices() {
    _dio = Dio(BaseOptions(baseUrl: endpoint));

    // Automatically attach token and handle refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            try {
              final oldRefreshToken = await _tokenManager.getRefreshToken();
              if (oldRefreshToken == null) {
                // await _logout();
                return handler.next(e);
              }

              final response = await Dio().post(
                '${endpoint}refresh',
                data: {'refresh_token': oldRefreshToken},
              );

              final newAccessToken = response.data['access_token'];

              await _tokenManager.saveTokens(
                accessToken: newAccessToken,
                refreshToken: oldRefreshToken,
              );

              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              await _logout();
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- AUTHENTICATION ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'login',
        data: {'username': username, 'password': password, 'email': 'user@example.com'},
      );

      await _tokenManager.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );

      return {'success': true, 'message': 'Login successful'};
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMsg = 'Something went wrong. Please try again.';
      if (data is Map && data['detail'] != null) {
        errorMsg = data['detail'].toString();
      } else if (data is String) {
        errorMsg = data;
      } else if (data != null) {
        errorMsg = data.toString();
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      return {'success': false, 'message': errorMsg};
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      await _dio.post(
        'register',
        data: {'username': username, 'email': email, 'password': password},
      );
      return {'success': true, 'message': 'Registration successful'};
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMsg = 'Something went wrong. Please try again.';
      if (data is Map && data['detail'] != null) {
        errorMsg = data['detail'].toString();
      } else if (data is String) {
        errorMsg = data;
      } else if (data != null) {
        errorMsg = data.toString();
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      return {'success': false, 'message': errorMsg};
    }
  }

  Future<void> _logout() async {
    await _tokenManager.deleteTokens();
    navigatorkey.currentContext?.go('/login');
  }

  // --- FINANCE API CALLS ---

  Future<Map> getBalance() async {
    final response = await _dio.get("getData");
    return response.data;
  }

  Future<void> debitTransaction(String amount, String reason, String category, int index) async {
    if (index == 3) {
      await mutualFundTransaction(amount, category, "debit", reason);
      return;
    }
    await _dio.get("debit", queryParameters: {"amount": amount, "reason": reason, "category": category, "area": backendAreaRoute[index.toString()]});
    Provider.of<SimpleProvider>(navigatorkey.currentContext!, listen: false).increment();
  }

  Future<void> creditTransaction(String amount, String reason, String category, int index) async {
    if (index == 3) {
      await mutualFundTransaction(amount, category, "credit", reason);
      return;
    }
    await _dio.get("credit", queryParameters: {"amount": amount, "reason": reason, "category": category, "area": backendAreaRoute[index.toString()]});
    Provider.of<SimpleProvider>(navigatorkey.currentContext!, listen: false).increment();
  }

  Future<void> mutualFundTransaction(String amount, String fundName, String method, String units) async {
    await _dio.get("mf-transaction", queryParameters: {"amount": amount, "fund_name": fundName, "method": method, "units": units});
    Provider.of<SimpleProvider>(navigatorkey.currentContext!, listen: false).increment();
  }

  Future<void> deleteTransaction(String id, String amount, String bracket, String mId, String method) async {
    await _dio.get("deleteTransaction", queryParameters: {"id": id, "amount": amount, "bracket": bracket, "m_id": mId, "method": method});
    Provider.of<SimpleProvider>(navigatorkey.currentContext!, listen: false).increment();
  }

  Future<Map> getTransactions(String month, String year) async {
    final response = await _dio.get("getTransactions", queryParameters: {"month": month, "year": year});
    return response.data;
  }

  Future<List> getChoices(String amount) async {
    final response = await _dio.get("getChoices", queryParameters: {"amount": amount});
    return response.data;
  }
}
