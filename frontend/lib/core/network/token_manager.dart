import 'package:localstorage/localstorage.dart';

class TokenManager {
  final LocalStorage _storage = LocalStorage('token_storage');

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.ready;
    _storage.setItem('access_token', accessToken);
    _storage.setItem('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() async {
    await _storage.ready;
    return _storage.getItem('access_token');
  }

  Future<String?> getRefreshToken() async {
    await _storage.ready;
    return _storage.getItem('refresh_token');
  }

  Future<bool> hasValidRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> deleteTokens() async {
    await _storage.ready;
    _storage.deleteItem('access_token');
    _storage.deleteItem('refresh_token');
  }
}
