import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';
import 'package:finance_dashboard/features/transactions/presentation/transaction_list_page.dart';

class MockTransactionsProvider extends ChangeNotifier
    implements TransactionsProvider {
  @override
  List<Map<String, dynamic>> transactions = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  TransactionsApi get _transactionsApi => throw UnimplementedError();

  int loadCallCount = 0;
  int deleteTransactionCallCount = 0;
  int? lastDeletedTransactionId;

  @override
  Future<void> load() async {
    loadCallCount++;
  }

  @override
  Future<void> addTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) async {}

  @override
  Future<void> deleteTransaction(int transactionId) async {
    deleteTransactionCallCount++;
    lastDeletedTransactionId = transactionId;
    transactions.removeWhere((t) => t['id'] == transactionId);
    notifyListeners();
  }
}

void main() {
  group('TransactionListPage', () {
    late MockTransactionsProvider mockTransactionsProvider;

    setUp(() {
      mockTransactionsProvider = MockTransactionsProvider();
    });

    Widget createWidgetUnderTest() {
      // The provider must wrap the whole MaterialApp (not just `home`) so
      // that dialogs shown via showDialog() - which are inserted as a
      // sibling overlay entry on the same root Navigator, not as a
      // descendant of `home` - can still look it up via context.read().
      return ChangeNotifierProvider<TransactionsProvider>.value(
        value: mockTransactionsProvider as TransactionsProvider,
        child: const MaterialApp(
          home: TransactionListPage(),
        ),
      );
    }

    group('UI elements', () {
      testWidgets('should display app bar with title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Transactions'), findsOneWidget);
      });

      testWidgets('should display scaffold with body', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should have a refresh action in the app bar', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real app bar exposes a manual refresh button
        expect(find.widgetWithIcon(AppBar, Icons.refresh), findsOneWidget);

        // Tapping it should call provider.load() again (initState already called it once)
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(mockTransactionsProvider.loadCallCount, equals(2));
      });
    });

    group('empty state', () {
      testWidgets('should display empty state icon and message when no transactions exist',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real empty state widgets are present
        expect(find.byIcon(Icons.receipt_long), findsOneWidget);
        expect(find.text('No transactions yet'), findsOneWidget);
      });

      testWidgets('should show message encouraging user to add first transaction when empty',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real widget renders this exact copy
        expect(find.text('Add your first transaction to get started'), findsOneWidget);
      });
    });

    group('transaction list rendering', () {
      testWidgets('should render transaction items when transactions exist',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - a real ListTile is rendered for the transaction, empty state is gone
        expect(find.byType(ListTile), findsOneWidget);
        expect(find.text('No transactions yet'), findsNothing);
      });

      testWidgets('should display category, amount, and date for each transaction',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real widget upper-cases category_code, formats amount with 2
        // decimals and a leading '$', and formats the date as 'MMM dd, yyyy'
        expect(find.text('FOOD'), findsOneWidget);
        expect(find.text('\$50.00'), findsOneWidget);
        expect(find.text('Sep 01, 2026'), findsOneWidget);
        expect(find.text('Lunch'), findsOneWidget);
      });

      testWidgets('should render multiple transaction items', (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
          {
            'id': 2,
            'category_code': 'transport',
            'amount': 20.0,
            'reason': 'Uber',
            'date': '2026-09-01T14:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - both transactions are rendered as distinct list tiles
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(find.text('FOOD'), findsOneWidget);
        expect(find.text('TRANSPORT'), findsOneWidget);
        expect(find.text('\$50.00'), findsOneWidget);
        expect(find.text('\$20.00'), findsOneWidget);
      });
    });

    group('overage transaction display', () {
      testWidgets('should show visual distinction for overage transactions',
          (WidgetTester tester) async {
        // Arrange - one normal and one overage transaction
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
          {
            'id': 2,
            'category_code': 'food',
            'amount': 150.0,
            'reason': 'Overspent',
            'date': '2026-09-01T14:00:00',
            'is_overage': true,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real is_overage branch renders a warning icon and an
        // 'OVERAGE' badge only for the overage transaction, while the normal
        // one gets the regular shopping-cart icon and no badge.
        expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
        expect(find.text('OVERAGE'), findsOneWidget);
      });

      testWidgets('should flag overage transactions with a tooltip for user awareness',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 150.0,
            'reason': 'Overspent',
            'date': '2026-09-01T14:00:00',
            'is_overage': true,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real widget wraps the warning icon in a Tooltip that
        // explains the overage status to the user
        final tooltipFinder = find.byTooltip('Over budget');
        expect(tooltipFinder, findsOneWidget);
      });
    });

    group('transaction deletion', () {
      testWidgets('should expose a delete affordance for each transaction',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real trailing delete icon button exists
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('should call provider.deleteTransaction with correct transaction ID',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 42,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act - tap the real delete icon, then confirm the real dialog
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Delete Transaction'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        // Assert - the exact transaction ID (42) was passed through
        expect(mockTransactionsProvider.deleteTransactionCallCount, equals(1));
        expect(mockTransactionsProvider.lastDeletedTransactionId, equals(42));
      });

      testWidgets('should remove transaction from list after successful deletion',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();
        expect(find.text('FOOD'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        // Assert - the deleted transaction is gone and the empty state shows
        expect(find.text('FOOD'), findsNothing);
        expect(find.text('No transactions yet'), findsOneWidget);
      });

      testWidgets('should not delete when the confirmation dialog is cancelled',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Assert - nothing was deleted
        expect(mockTransactionsProvider.deleteTransactionCallCount, equals(0));
        expect(find.text('FOOD'), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('should display loading indicator while fetching transactions',
          (WidgetTester tester) async {
        // Arrange - loading with no transactions yet loaded
        mockTransactionsProvider.isLoading = true;
        mockTransactionsProvider.transactions = [];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Assert - the real loading branch renders a CircularProgressIndicator
        // instead of the empty state or list
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('No transactions yet'), findsNothing);
      });
    });

    group('error handling', () {
      testWidgets('should display error message if loading fails',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.errorMessage = 'Failed to load transactions';
        mockTransactionsProvider.transactions = [];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - the real error branch renders the exact error message and
        // a retry action
        expect(find.text('Failed to load transactions'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
      });

      testWidgets('tapping Retry calls provider.load() again', (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.errorMessage = 'Failed to load transactions';
        mockTransactionsProvider.transactions = [];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();
        final loadsBeforeRetry = mockTransactionsProvider.loadCallCount;

        await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
        await tester.pumpAndSettle();

        // Assert
        expect(mockTransactionsProvider.loadCallCount, equals(loadsBeforeRetry + 1));
      });
    });

    group('pull-to-refresh', () {
      testWidgets('should support pull-to-refresh to reload transactions',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // The real widget wraps the list in a RefreshIndicator
        expect(find.byType(RefreshIndicator), findsOneWidget);
        final loadsBeforeRefresh = mockTransactionsProvider.loadCallCount;

        // Simulate a pull-to-refresh drag gesture on the list
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - provider.load() was invoked again by the drag
        expect(mockTransactionsProvider.loadCallCount, equals(loadsBeforeRefresh + 1));
      });
    });

    group('transaction interaction', () {
      testWidgets(
          'should update when provider.transactions changes (real-time update)',
          (WidgetTester tester) async {
        // Initial empty state
        mockTransactionsProvider.transactions = [];

        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();
        expect(find.text('No transactions yet'), findsOneWidget);

        // Now add a transaction by updating the provider
        mockTransactionsProvider.transactions = [
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];
        mockTransactionsProvider.notifyListeners();

        // Pump to rebuild
        await tester.pumpAndSettle();

        // Assert - the list now renders the new transaction and the empty
        // state is gone
        expect(find.text('No transactions yet'), findsNothing);
        expect(find.text('FOOD'), findsOneWidget);
      });
    });
  });
}
