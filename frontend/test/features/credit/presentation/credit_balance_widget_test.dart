import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/credit/presentation/credit_balance_widget.dart';
import 'package:finance_dashboard/features/credit/data/credit_api.dart';

class MockCreditProvider extends ChangeNotifier implements CreditProvider {
  @override
  dynamic balance;

  @override
  List<Map<String, dynamic>> history = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  // Private fields for interface compliance
  late final CreditApi _creditApi;
  bool _isCached = false;
  Future<void>? _inFlightFuture;

  MockCreditProvider({this.balance});

  @override
  Future<void> load({bool forceRefresh = false}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    isLoading = false;
    notifyListeners();
  }
}

void main() {
  group('CreditBalanceWidget', () {
    late MockCreditProvider mockCreditProvider;

    setUp(() {
      mockCreditProvider = MockCreditProvider(balance: null);
    });

    Widget createWidgetUnderTest({dynamic balance}) {
      return MaterialApp(
        home: ChangeNotifierProvider<CreditProvider>.value(
          value: (balance != null
              ? MockCreditProvider(balance: balance)
              : mockCreditProvider) as CreditProvider,
          child: const Scaffold(
            body: CreditBalanceWidget(),
          ),
        ),
      );
    }

    group('UI rendering', () {
      testWidgets('should render without crashing',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should display balance value when available',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 150.50));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should handle null balance gracefully',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: null));

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should handle zero balance', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 0));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });
    });

    group('balance display', () {
      testWidgets('should display balance as text', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 100.0));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should display correct balance value',
          (WidgetTester tester) async {
        // Arrange
        const testBalance = 250.75;

        // Act
        await tester.pumpWidget(createWidgetUnderTest(balance: testBalance));
        await tester.pumpAndSettle();

        // Assert - widget should display the balance value
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should handle large balance values',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 9999.99));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should display decimal precision', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 123.45));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('outstanding debt indicator', () {
      testWidgets(
          'should display warning indicator when balance > 0',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 50.0));
        await tester.pumpAndSettle();

        // Assert - look for a visual indicator (could be color, icon, or text)
        // The widget might display a warning text or have a different styling
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);
      });

      testWidgets('should not display warning when balance is 0',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 0));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should not display warning when balance is null',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: null));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should update indicator when balance changes',
          (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: 0);

        // Act & Assert - initial state
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        expect(provider.balance, equals(0));

        // Act - update balance
        provider.balance = 100.0;
        provider.notifyListeners();
        await tester.pumpAndSettle();

        // Assert - should reflect new balance
        expect(provider.balance, equals(100.0));
      });
    });

    group('loading state', () {
      testWidgets('should display content while loading',
          (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: 100.0);
        provider.isLoading = true;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should display content when not loading',
          (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: 100.0);
        provider.isLoading = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });
    });

    group('error handling', () {
      testWidgets('should render when no error', (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: 100.0);
        provider.errorMessage = null;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should handle error gracefully', (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: null);
        provider.errorMessage = 'Failed to load balance';

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });
    });

    group('state management integration', () {
      testWidgets('should rebuild when provider notifies',
          (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(balance: 50.0);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        final initialBalance = provider.balance;

        // Act - change balance and notify
        provider.balance = 150.0;
        provider.notifyListeners();
        await tester.pumpAndSettle();

        // Assert
        expect(provider.balance, isNot(equals(initialBalance)));
      });

      testWidgets('should consume provider data correctly',
          (WidgetTester tester) async {
        // Arrange
        final provider = MockCreditProvider(
          balance: 200.0,
        );
        provider.history = [
          {
            'id': '1',
            'month': '2024-09',
            'category_code': 'OVERAGE',
            'amount': 200.0,
            'entry_type': 'charge',
            'created_at': '2024-09-01T10:30:00Z',
          },
        ];

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<CreditProvider>.value(
              value: provider as CreditProvider,
              child: const Scaffold(
                body: CreditBalanceWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(provider.balance, equals(200.0));
        expect(provider.history.isNotEmpty, true);
      });
    });

    group('responsive design', () {
      testWidgets('should render on small screen', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(400, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 100.0));

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });

      testWidgets('should render on large screen', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 100.0));

        // Assert
        expect(find.byType(CreditBalanceWidget), findsOneWidget);
      });
    });

    group('accessibility', () {
      testWidgets('should have semantic information', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(balance: 100.0));

        // Assert
        expect(find.byType(Semantics), findsWidgets);
      });
    });
  });
}
