import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';
import 'package:finance_dashboard/features/transactions/presentation/transaction_entry_page.dart';
import 'package:finance_dashboard/features/categories/business/categories_provider.dart';
import 'package:finance_dashboard/features/categories/data/categories_api.dart';

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

  int addTransactionCallCount = 0;
  String? lastAddedCategoryCode;
  num? lastAddedAmount;
  String? lastAddedReason;
  DateTime? lastAddedDate;

  @override
  Future<void> load() async {}

  @override
  Future<void> addTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) async {
    addTransactionCallCount++;
    lastAddedCategoryCode = categoryCode;
    lastAddedAmount = amount;
    lastAddedReason = reason;
    lastAddedDate = date;
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {}
}

class MockCategoriesProvider extends ChangeNotifier
    implements CategoriesProvider {
  @override
  List<Map<String, dynamic>> categories = [
    {'code': 'food', 'name': 'Food', 'limit': 500},
    {'code': 'transport', 'name': 'Transport', 'limit': 200},
    {'code': 'utilities', 'name': 'Utilities', 'limit': 300},
  ];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  CategoriesApi get _categoriesApi => throw UnimplementedError();

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

void main() {
  group('TransactionEntryPage', () {
    late MockTransactionsProvider mockTransactionsProvider;
    late MockCategoriesProvider mockCategoriesProvider;

    setUp(() {
      mockTransactionsProvider = MockTransactionsProvider();
      mockCategoriesProvider = MockCategoriesProvider();
    });

    Widget createWidgetUnderTest() {
      // The entry page is normally reached by pushing it onto a stack, and
      // its submit flow calls Navigator.pop(context) on success. Wrap it in
      // a Builder-driven push so that pop has somewhere real to go back to,
      // instead of popping the app's only route. The providers must wrap the
      // whole MaterialApp (and therefore its Navigator) so that pushed routes
      // can still see them.
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TransactionsProvider>.value(
            value: mockTransactionsProvider as TransactionsProvider,
          ),
          ChangeNotifierProvider<CategoriesProvider>.value(
            value: mockCategoriesProvider as CategoriesProvider,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionEntryPage(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Pumps the widget under test and navigates straight to the entry page.
    Future<void> pumpEntryPage(WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> selectCategory(WidgetTester tester, String displayName) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(displayName).last);
      await tester.pumpAndSettle();
    }

    group('UI elements', () {
      testWidgets('should display app bar with title', (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('New Transaction'), findsOneWidget);
      });

      testWidgets('should display form fields for category, amount, reason and date',
          (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);

        // Assert
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should display scaffold with body', (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);

        // Assert
        expect(find.byType(Scaffold), findsWidgets);
      });
    });

    group('form validation - category', () {
      testWidgets('should require category selection and block submission',
          (WidgetTester tester) async {
        // Arrange - fill amount but leave category unselected
        await pumpEntryPage(tester);
        await tester.enterText(find.byType(TextFormField).at(0), '25.00');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - the real validator message is shown and the provider was
        // never called
        expect(find.text('Please select a category'), findsOneWidget);
        expect(mockTransactionsProvider.addTransactionCallCount, equals(0));
      });
    });

    group('form validation - amount', () {
      testWidgets('should require amount input and block submission',
          (WidgetTester tester) async {
        // Arrange - select a category but leave amount empty
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter an amount'), findsOneWidget);
        expect(mockTransactionsProvider.addTransactionCallCount, equals(0));
      });

      testWidgets('should validate amount is a positive number', (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');
        await tester.enterText(find.byType(TextFormField).at(0), '-5');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Amount must be greater than 0'), findsOneWidget);
        expect(mockTransactionsProvider.addTransactionCallCount, equals(0));
      });

      testWidgets('should reject non-numeric amount input', (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');
        await tester.enterText(find.byType(TextFormField).at(0), 'abc');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter a valid number'), findsOneWidget);
        expect(mockTransactionsProvider.addTransactionCallCount, equals(0));
      });
    });

    group('form submission', () {
      testWidgets('should call provider.addTransaction when form is valid and submitted',
          (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');
        await tester.enterText(find.byType(TextFormField).at(0), '50.00');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(mockTransactionsProvider.addTransactionCallCount, equals(1));
      });

      testWidgets('should pass the entered category, amount, and null reason to the provider',
          (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Transport');
        await tester.enterText(find.byType(TextFormField).at(0), '19.99');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - exact values reach the provider
        expect(mockTransactionsProvider.lastAddedCategoryCode, equals('transport'));
        expect(mockTransactionsProvider.lastAddedAmount, equals(19.99));
        expect(mockTransactionsProvider.lastAddedReason, isNull);
        expect(mockTransactionsProvider.lastAddedDate, isNotNull);
      });

      testWidgets('should pass the entered reason to the provider when provided',
          (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');
        await tester.enterText(find.byType(TextFormField).at(0), '50.00');
        await tester.enterText(find.byType(TextFormField).at(1), 'Lunch at restaurant');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - the optional reason field is not required, but when filled
        // in it is passed through verbatim
        expect(mockTransactionsProvider.lastAddedReason, equals('Lunch at restaurant'));
      });

      testWidgets('should show a success snack bar and pop after submitting',
          (WidgetTester tester) async {
        // Arrange
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Food');
        await tester.enterText(find.byType(TextFormField).at(0), '50.00');

        // Act
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - the entry page popped back to the launcher screen and a
        // success message was shown
        expect(find.text('Transaction created successfully'), findsOneWidget);
        expect(find.text('New Transaction'), findsNothing);
      });
    });

    group('date handling', () {
      testWidgets('should default to today\'s date, formatted for display',
          (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);

        // Assert - the real widget defaults _selectedDate to DateTime.now()
        // and renders it as 'MMM dd, yyyy'
        final expectedLabel = DateFormat('MMM dd, yyyy').format(DateTime.now());
        expect(find.text(expectedLabel), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });
    });

    group('error handling', () {
      testWidgets('should display the provider error message when transaction creation fails',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.errorMessage = 'Failed to create transaction';

        // Act
        await pumpEntryPage(tester);

        // Assert - the real error container renders the exact message
        expect(find.text('Failed to create transaction'), findsOneWidget);
      });

      testWidgets('should not display an error container when there is no error',
          (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);

        // Assert
        expect(mockTransactionsProvider.errorMessage, isNull);
        expect(find.text('Failed to create transaction'), findsNothing);
      });
    });

    group('loading state', () {
      testWidgets('should show a loading indicator instead of the submit button while submitting',
          (WidgetTester tester) async {
        // Arrange
        mockTransactionsProvider.isLoading = true;

        // Act - can't use pumpAndSettle here: the CircularProgressIndicator
        // animates forever and would time the settle out.
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump();

        // Assert - the real widget swaps the submit button for a spinner
        // while transactionsProvider.isLoading is true
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Create Transaction'), findsNothing);
      });
    });

    group('category selection', () {
      testWidgets('should populate the dropdown with the real categories from CategoriesProvider',
          (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Assert - the dropdown lists exactly the categories sourced from
        // CategoriesProvider.categories
        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Utilities'), findsOneWidget);
      });

      testWidgets('should update the selected value when a category is chosen',
          (WidgetTester tester) async {
        // Arrange & Act
        await pumpEntryPage(tester);
        await selectCategory(tester, 'Utilities');

        // Assert - the dropdown now displays the chosen category and the
        // "select a category" hint is gone
        expect(find.text('Utilities'), findsOneWidget);
        expect(find.text('Select a category'), findsNothing);
      });
    });
  });
}
