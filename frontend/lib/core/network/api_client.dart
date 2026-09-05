import 'package:dio/dio.dart';
import 'package:finance_dashboard/constants/globals.dart';
import 'package:finance_dashboard/core/network/token_manager.dart';
import 'package:go_router/go_router.dart';

class ApiClient {
  late Dio _dio;
  final TokenManager _tokenManager = TokenManager();

  static const String endpoint = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "/",
  );

  ApiClient() {
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
                // No refresh token available; propagate the 401
                return handler.next(e);
              }

              final response = await Dio().post(
                '${endpoint}auth/refresh',
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

  Dio get dio => _dio;

  Future<void> _logout() async {
    await _tokenManager.deleteTokens();
    navigatorkey.currentContext?.go('/auth');
  }
}
