import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/auth/data/auth_api.dart';

// Mock classes for testing
class MockDio extends Mock implements Dio {}

void main() {
  group('AuthApi', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('login', () {
      test('should call POST /auth/login with username and password', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        final responseData = {
          'access_token': 'access_token_value',
          'refresh_token': 'refresh_token_value',
        };

        when(
          () => mockDio.post(
            '/auth/login',
            data: {'username': username, 'password': password},
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        await authApi.login(username, password);

        // Assert
        verify(
          () => mockDio.post(
            '/auth/login',
            data: {'username': username, 'password': password},
          ),
        ).called(1);
      });

      test('should return access_token and refresh_token on successful login',
          () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        final responseData = {
          'access_token': accessToken,
          'refresh_token': refreshToken,
        };

        when(
          () => mockDio.post(
            '/auth/login',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        final result = await authApi.login(username, password);

        // Assert
        expect(result['access_token'], equals(accessToken));
        expect(result['refresh_token'], equals(refreshToken));
      });

      test('should throw exception on login failure with 401 status', () async {
        // Arrange
        const username = 'testuser';
        const password = 'wrongpassword';

        when(
          () => mockDio.post(
            '/auth/login',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              statusCode: 401,
              data: {'detail': 'Invalid credentials'},
              requestOptions: RequestOptions(path: '/auth/login'),
            ),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.login(username, password),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid credentials'),
          )),
        );
      });

      test('should throw exception on login failure with network error',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/login',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/auth/login'),
            message: 'Connection timeout',
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.login('testuser', 'password'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Connection timeout'),
          )),
        );
      });

      test('should throw exception on login failure with 500 status',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/login',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/auth/login'),
            ),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.login('testuser', 'password'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });
    });

    group('register', () {
      test('should call POST /auth/register with username, email, and password',
          () async {
        // Arrange
        const username = 'newuser';
        const email = 'newuser@example.com';
        const password = 'password123';
        final responseData = {
          'user_id': '123',
          'username': username,
          'email': email,
        };

        when(
          () => mockDio.post(
            '/auth/register',
            data: {
              'username': username,
              'email': email,
              'password': password,
            },
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/auth/register'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        await authApi.register(username, email, password);

        // Assert
        verify(
          () => mockDio.post(
            '/auth/register',
            data: {
              'username': username,
              'email': email,
              'password': password,
            },
          ),
        ).called(1);
      });

      test('should return user data on successful register',
          () async {
        // Arrange
        const username = 'newuser';
        const email = 'newuser@example.com';
        const password = 'password123';

        final responseData = {
          'user_id': '123',
          'username': username,
          'email': email,
        };

        when(
          () => mockDio.post(
            '/auth/register',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/auth/register'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        final result = await authApi.register(username, email, password);

        // Assert
        expect(result['user_id'], equals('123'));
        expect(result['username'], equals(username));
        expect(result['email'], equals(email));
      });

      test('should throw exception on register failure with 400 status',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/register',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/register'),
            response: Response(
              statusCode: 400,
              data: {'detail': 'Username or email already exists'},
              requestOptions: RequestOptions(path: '/auth/register'),
            ),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.register('newuser', 'email@example.com', 'password'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Username or email already exists'),
          )),
        );
      });

      test('should throw exception on register failure with network error',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/register',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/auth/register'),
            message: 'Connection timeout',
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.register('newuser', 'email@example.com', 'password'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Connection timeout'),
          )),
        );
      });

      test('should throw exception on register failure with 500 status',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/register',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/register'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/auth/register'),
            ),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.register('newuser', 'email@example.com', 'password'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });
    });

    group('refresh', () {
      test('should call POST /auth/refresh with refresh_token', () async {
        // Arrange
        const refreshToken = 'old_refresh_token';
        final responseData = {
          'access_token': 'new_access_token',
        };

        when(
          () => mockDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        await authApi.refresh(refreshToken);

        // Assert
        verify(
          () => mockDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          ),
        ).called(1);
      });

      test('should return new access_token on successful refresh', () async {
        // Arrange
        const refreshToken = 'old_refresh_token';
        const newAccessToken = 'new_access_token';

        final responseData = {
          'access_token': newAccessToken,
        };

        when(
          () => mockDio.post(
            '/auth/refresh',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act
        final result = await authApi.refresh(refreshToken);

        // Assert
        expect(result['access_token'], equals(newAccessToken));
      });

      test('should throw exception on refresh failure with 401 status',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/refresh',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            response: Response(
              statusCode: 401,
              data: {'detail': 'Invalid refresh token'},
              requestOptions: RequestOptions(path: '/auth/refresh'),
            ),
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.refresh('invalid_token'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid refresh token'),
          )),
        );
      });

      test('should throw exception on refresh failure with network error',
          () async {
        // Arrange
        when(
          () => mockDio.post(
            '/auth/refresh',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            message: 'Connection timeout',
          ),
        );

        final authApi = AuthApi(mockDio);

        // Act & Assert
        expect(
          () => authApi.refresh('refresh_token'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Connection timeout'),
          )),
        );
      });
    });
  });
}
