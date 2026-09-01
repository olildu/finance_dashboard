import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/auth/business/auth_provider.dart';
import 'package:finance_dashboard/features/auth/data/auth_api.dart';
import 'package:finance_dashboard/core/network/token_manager.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenManager extends Mock implements TokenManager {}

void main() {
  group('AuthProvider', () {
    late MockAuthApi mockAuthApi;
    late MockTokenManager mockTokenManager;

    setUp(() {
      mockAuthApi = MockAuthApi();
      mockTokenManager = MockTokenManager();
    });

    group('initialization', () {
      test('should initialize with isLoggedIn as false', () {
        // Act
        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Assert
        expect(authProvider.isLoggedIn, false);
      });

      test('should initialize currentError as null', () {
        // Act
        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Assert
        expect(authProvider.currentError, isNull);
      });
    });

    group('login', () {
      test('should successfully login and set isLoggedIn to true', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        when(
          () => mockAuthApi.login(username, password),
        ).thenAnswer(
          (_) async => {
            'access_token': accessToken,
            'refresh_token': refreshToken,
          },
        );

        when(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.login(username, password);

        // Assert
        expect(authProvider.isLoggedIn, true);
      });

      test('should clear error on successful login', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        when(
          () => mockAuthApi.login(username, password),
        ).thenAnswer(
          (_) async => {
            'access_token': accessToken,
            'refresh_token': refreshToken,
          },
        );

        when(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.login(username, password);

        // Assert
        expect(authProvider.currentError, isNull);
      });

      test('should set currentError and keep isLoggedIn false on login failure',
          () async {
        // Arrange
        const username = 'testuser';
        const password = 'wrongpassword';
        const errorMessage = 'Invalid credentials';

        when(
          () => mockAuthApi.login(username, password),
        ).thenThrow(Exception(errorMessage));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.login(username, password);
        } catch (_) {}

        // Assert
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.currentError, contains(errorMessage));
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';

        when(
          () => mockAuthApi.login(username, password),
        ).thenThrow(Exception('Network error: Connection timeout'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.login(username, password);
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, isNotNull);
        expect(authProvider.isLoggedIn, false);
      });

      test('should handle server errors gracefully', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';

        when(
          () => mockAuthApi.login(username, password),
        ).thenThrow(Exception('Server error: 500 Internal Server Error'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.login(username, password);
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, isNotNull);
        expect(authProvider.isLoggedIn, false);
      });

      test('should call tokenManager.saveTokens with correct tokens', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        when(
          () => mockAuthApi.login(username, password),
        ).thenAnswer(
          (_) async => {
            'access_token': accessToken,
            'refresh_token': refreshToken,
          },
        );

        when(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.login(username, password);

        // Assert
        verify(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).called(1);
      });
    });

    group('register', () {
      test('should call register then login after successful registration',
          () async {
        // Arrange
        const username = 'newuser';
        const email = 'newuser@example.com';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        when(
          () => mockAuthApi.register(username, email, password),
        ).thenAnswer(
          (_) async => {
            'user_id': '123',
            'username': username,
            'email': email,
          },
        );

        when(
          () => mockAuthApi.login(username, password),
        ).thenAnswer(
          (_) async => {
            'access_token': accessToken,
            'refresh_token': refreshToken,
          },
        );

        when(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.register(username, email, password);

        // Assert
        expect(authProvider.isLoggedIn, true);
        expect(authProvider.currentError, isNull);
        verify(() => mockAuthApi.register(username, email, password))
            .called(1);
        verify(() => mockAuthApi.login(username, password)).called(1);
      });

      test('should set currentError on register failure', () async {
        // Arrange
        const username = 'newuser';
        const email = 'newuser@example.com';
        const password = 'password123';
        const errorMessage = 'Username already exists';

        when(
          () => mockAuthApi.register(username, email, password),
        ).thenThrow(Exception(errorMessage));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.register(username, email, password);
        } catch (_) {}

        // Assert
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.currentError, contains(errorMessage));
      });

      test('should handle duplicate username error', () async {
        // Arrange
        const username = 'existinguser';
        const email = 'newemail@example.com';
        const password = 'password123';

        when(
          () => mockAuthApi.register(username, email, password),
        ).thenThrow(Exception('Username already exists'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.register(username, email, password);
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, contains('Username already exists'));
      });

      test('should handle duplicate email error', () async {
        // Arrange
        const username = 'newuser';
        const email = 'existing@example.com';
        const password = 'password123';

        when(
          () => mockAuthApi.register(username, email, password),
        ).thenThrow(Exception('Email already registered'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.register(username, email, password);
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, contains('Email already registered'));
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        const username = 'newuser';
        const email = 'newuser@example.com';
        const password = 'password123';

        when(
          () => mockAuthApi.register(username, email, password),
        ).thenThrow(Exception('Network error: Connection timeout'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        try {
          await authProvider.register(username, email, password);
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, isNotNull);
        expect(authProvider.isLoggedIn, false);
      });
    });

    group('logout', () {
      test('should set isLoggedIn to false on logout', () async {
        // Arrange
        when(
          () => mockTokenManager.deleteTokens(),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.isLoggedIn, false);
      });

      test('should delete tokens on logout', () async {
        // Arrange
        when(
          () => mockTokenManager.deleteTokens(),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.logout();

        // Assert
        verify(
          () => mockTokenManager.deleteTokens(),
        ).called(1);
      });

      test('should clear currentError on logout', () async {
        // Arrange
        when(
          () => mockTokenManager.deleteTokens(),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.currentError, isNull);
      });

      test('should handle token deletion errors gracefully', () async {
        // Arrange
        when(
          () => mockTokenManager.deleteTokens(),
        ).thenThrow(Exception('Failed to delete tokens'));

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.currentError, isNotNull);
      });
    });

    group('state management', () {
      test('should maintain isLoggedIn state across multiple operations',
          () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const accessToken = 'access_token_value';
        const refreshToken = 'refresh_token_value';

        when(
          () => mockAuthApi.login(username, password),
        ).thenAnswer(
          (_) async => {
            'access_token': accessToken,
            'refresh_token': refreshToken,
          },
        );

        when(
          () => mockTokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockTokenManager.deleteTokens(),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act - Login
        await authProvider.login(username, password);

        // Assert
        expect(authProvider.isLoggedIn, true);

        // Act - Logout
        await authProvider.logout();

        // Assert
        expect(authProvider.isLoggedIn, false);
      });

      test('should accumulate errors only on failures', () async {
        // Arrange
        when(
          () => mockAuthApi.login('wrong', 'wrong'),
        ).thenThrow(Exception('Invalid credentials'));

        when(
          () => mockTokenManager.deleteTokens(),
        ).thenAnswer((_) async {});

        final authProvider = AuthProvider(
          authApi: mockAuthApi,
          tokenManager: mockTokenManager,
        );

        // Act - Failed login
        try {
          await authProvider.login('wrong', 'wrong');
        } catch (_) {}

        // Assert
        expect(authProvider.currentError, isNotNull);

        // Act - Logout
        await authProvider.logout();

        // Assert
        expect(authProvider.currentError, isNull);
      });
    });
  });
}
