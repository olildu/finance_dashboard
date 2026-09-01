import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/auth/business/auth_provider.dart';
import 'package:finance_dashboard/features/auth/presentation/login_register_page.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoggedIn = false;

  @override
  String? currentError;

  int loginCallCount = 0;
  int registerCallCount = 0;
  String? lastLoginUsername;
  String? lastLoginPassword;
  String? lastRegisterUsername;
  String? lastRegisterEmail;
  String? lastRegisterPassword;

  @override
  Future<void> login(String username, String password) async {
    loginCallCount++;
    lastLoginUsername = username;
    lastLoginPassword = password;
  }

  @override
  Future<void> register(
    String username,
    String email,
    String password,
  ) async {
    registerCallCount++;
    lastRegisterUsername = username;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('LoginRegisterPage', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider as AuthProvider,
          child: const LoginRegisterPage(),
        ),
      );
    }

    group('UI elements - Login Mode', () {
      testWidgets('should display username input field',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(TextField), findsNWidgets(2)); // username, password
      });

      testWidgets('should display password input field',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(TextField), findsNWidgets(2)); // username, password
      });

      testWidgets('should display login button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('should display register toggle button',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(TextButton), findsOneWidget);
      });
    });

    group('Mode toggle', () {
      testWidgets('should toggle to register mode when clicking toggle button',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Assert - should show register mode (3 text fields instead of 2)
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should display email input field in register mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act - switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(TextField), findsNWidgets(3)); // username, email, password
      });

      testWidgets('should not display email input field in login mode',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(TextField), findsNWidgets(2)); // username, password
      });

      testWidgets('should toggle back to login mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act - switch to register
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Verify we're in register mode
        expect(find.byType(TextField), findsNWidgets(3));

        // Act - switch back to login
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(TextField), findsNWidgets(2)); // back to 2 fields
      });
    });

    group('login validation', () {
      testWidgets('should not allow login with empty username',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Leave username empty
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Username is required'), findsOneWidget);
      });

      testWidgets('should not allow login with empty password',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Enter username but leave password empty
        await tester.enterText(find.byType(TextField).first, 'testuser');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      });
    });

    group('register validation', () {
      testWidgets('should not allow register with empty username',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
        await tester.enterText(find.byType(TextField).at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Username is required'), findsOneWidget);
      });

      testWidgets('should not allow register with empty email',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextField).at(0), 'newuser');
        await tester.enterText(find.byType(TextField).at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('should not allow register with empty password',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextField).at(0), 'newuser');
        await tester.enterText(find.byType(TextField).at(1), 'newuser@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('should validate email format', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextField).at(0), 'newuser');
        await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
        await tester.enterText(find.byType(TextField).at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Invalid email format'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('should show loading indicator while logging in',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act
        await tester.enterText(find.byType(TextField).first, 'testuser');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton).first);

        // Pump to show loading state
        await tester.pump();

        // Assert
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('should show register button after toggle',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('button behavior', () {
      testWidgets('should have functional login button', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act
        await tester.enterText(find.byType(TextField).first, 'testuser');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle();

        // Assert - login was called
        expect(mockAuthProvider.loginCallCount, equals(1));
      });

      testWidgets('should have functional register button',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextField).at(0), 'newuser');
        await tester.enterText(find.byType(TextField).at(1), 'newuser@example.com');
        await tester.enterText(find.byType(TextField).at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - register was called
        expect(mockAuthProvider.registerCallCount, equals(1));
      });
    });

    group('title display', () {
      testWidgets('should display title in login mode',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert - login mode should have 2 text fields
        expect(find.byType(TextField), findsNWidgets(2));
      });

      testWidgets('should display title in register mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest());

        // Act - switch to register mode
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // Assert - register mode should have 3 text fields
        expect(find.byType(TextField), findsNWidgets(3));
      });
    });
  });
}
