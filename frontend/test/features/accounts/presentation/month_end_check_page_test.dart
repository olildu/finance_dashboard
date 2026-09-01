import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/features/accounts/presentation/month_end_check_page.dart';

// Simple fake provider for testing
class FakeAccountsProvider extends ChangeNotifier implements AccountsProvider {
  @override
  List<Map<String, dynamic>> accounts = [];
  @override
  Map<String, dynamic>? monthEndCheck;
  @override
  bool isLoading = false;
  @override
  String? errorMessage;

  @override
  Future<void> load() async {
    // Default implementation does nothing
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }

  void setMonthEndCheck(Map<String, dynamic>? data) {
    monthEndCheck = data;
    notifyListeners();
  }

  void setAccounts(List<Map<String, dynamic>> data) {
    accounts = data;
    notifyListeners();
  }
}

// Not using AccountsApi in test widget, just for interface compatibility

void main() {
  group('MonthEndCheckPage', () {
    late FakeAccountsProvider fakeAccountsProvider;

    setUp(() {
      fakeAccountsProvider = FakeAccountsProvider();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<AccountsProvider>.value(
          value: fakeAccountsProvider as AccountsProvider,
          child: const MonthEndCheckPage(),
        ),
      );
    }

    group('UI elements', () {
      testWidgets('should display page title', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Month End Check'), findsOneWidget);
      });

      testWidgets('should display hdfc_reserve amount', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1500.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('HDFC Reserve'), findsOneWidget);
        expect(find.text('1,500.00'), findsOneWidget);
      });

      testWidgets('should display total_net_worth amount', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 75000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Total Net Worth'), findsOneWidget);
        expect(find.text('75,000.00'), findsOneWidget);
      });

      testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
        fakeAccountsProvider.setLoading(true);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should not display loading indicator when isLoading is false', (WidgetTester tester) async {
        fakeAccountsProvider.setLoading(false);
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should display error message when errorMessage is set', (WidgetTester tester) async {
        fakeAccountsProvider.setError('Failed to load accounts');

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Failed to load accounts'), findsOneWidget);
      });

      testWidgets('should not display error message initially', (WidgetTester tester) async {
        fakeAccountsProvider.setError(null);
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Error'), findsNothing);
      });

      testWidgets('should display account balances', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'ICICI': {'expected_balance': 5000.0},
          'SBI': {'expected_balance': 3000.0},
          'SLICE': {'expected_balance': 2000.0},
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('ICICI'), findsOneWidget);
        expect(find.text('SBI'), findsOneWidget);
        expect(find.text('SLICE'), findsOneWidget);
        expect(find.text('5,000.00'), findsOneWidget);
        expect(find.text('3,000.00'), findsOneWidget);
        expect(find.text('2,000.00'), findsOneWidget);
      });

      testWidgets('should format currency amounts', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1234.56,
          'total_net_worth': 50000.00,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('1,234.56'), findsOneWidget);
        expect(find.text('50,000.00'), findsOneWidget);
      });

      testWidgets('should handle empty accounts list', (WidgetTester tester) async {
        fakeAccountsProvider.setAccounts([]);
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 0.0,
          'total_net_worth': 0.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Account Balances'), findsOneWidget);
      });

      testWidgets('should have refresh button', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('data rendering', () {
      testWidgets('should render all account balances correctly', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'ICICI': {'expected_balance': 5000.0},
          'SBI': {'expected_balance': 10000.0},
          'SLICE': {'expected_balance': 35000.0},
          'hdfc_reserve': 1000.0,
          'total_net_worth': 51000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('ICICI'), findsOneWidget);
        expect(find.text('SBI'), findsOneWidget);
        expect(find.text('SLICE'), findsOneWidget);
        expect(find.text('5,000.00'), findsOneWidget);
        expect(find.text('10,000.00'), findsOneWidget);
        expect(find.text('35,000.00'), findsOneWidget);
      });

      testWidgets('should preserve decimal precision in display', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1234.56,
          'total_net_worth': 50000.99,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('1,234.56'), findsOneWidget);
        expect(find.text('50,000.99'), findsOneWidget);
      });

      testWidgets('should handle zero balance correctly', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 0.0,
          'total_net_worth': 0.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('0.00'), findsWidgets);
      });

      testWidgets('should handle negative balance correctly', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': -500.0,
          'total_net_worth': 49500.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('-500.00'), findsOneWidget);
      });

      testWidgets('should handle large numbers correctly', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000000.0,
          'total_net_worth': 9999999.99,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('1,000,000.00'), findsOneWidget);
        expect(find.text('9,999,999.99'), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('should have refresh button', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('state transitions', () {
      testWidgets('should update UI when isLoading changes', (WidgetTester tester) async {
        fakeAccountsProvider.setLoading(false);
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should update UI when errorMessage changes', (WidgetTester tester) async {
        fakeAccountsProvider.setError(null);
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Error'), findsNothing);
      });

      testWidgets('should update UI when monthEndCheck data changes', (WidgetTester tester) async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('1,000.00'), findsOneWidget);
      });
    });

    group('error handling', () {
      testWidgets('should display network error message', (WidgetTester tester) async {
        fakeAccountsProvider.setError('Network error: Connection timeout');
        fakeAccountsProvider.setLoading(false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Network error: Connection timeout'), findsOneWidget);
      });

      testWidgets('should display authorization error message', (WidgetTester tester) async {
        fakeAccountsProvider.setError('Unauthorized: Please login again');
        fakeAccountsProvider.setLoading(false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Unauthorized: Please login again'), findsOneWidget);
      });

      testWidgets('should display server error message', (WidgetTester tester) async {
        fakeAccountsProvider.setError('Server error: 500 Internal Server Error');
        fakeAccountsProvider.setLoading(false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Server error: 500 Internal Server Error'), findsOneWidget);
      });
    });
  });
}
