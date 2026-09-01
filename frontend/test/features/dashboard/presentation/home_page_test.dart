import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';
import 'package:finance_dashboard/features/dashboard/presentation/home_page.dart';

/// Fake AccountsProvider for testing
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
  Future<void> load() async {}

  FakeAccountsProvider({Map<String, dynamic>? monthEndCheckData}) {
    monthEndCheck = monthEndCheckData;
  }
}

/// Fake BudgetsProvider for testing
class FakeBudgetsProvider extends ChangeNotifier implements BudgetsProvider {
  @override
  List<Map<String, dynamic>> categories = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  FakeBudgetsProvider({List<Map<String, dynamic>>? categoriesData}) {
    categories = categoriesData ?? [];
  }
}

/// Fake CreditProvider for testing
class FakeCreditProvider extends ChangeNotifier implements CreditProvider {
  @override
  dynamic balance;

  @override
  List<Map<String, dynamic>> history = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  FakeCreditProvider({dynamic balanceData}) {
    balance = balanceData;
  }
}

/// Fake TransactionsProvider for testing
class FakeTransactionsProvider extends ChangeNotifier
    implements TransactionsProvider {
  @override
  List<Map<String, dynamic>> transactions = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  Future<void> load() async {}

  @override
  Future<void> addTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) async {}

  @override
  Future<void> deleteTransaction(int transactionId) async {}

  FakeTransactionsProvider({List<Map<String, dynamic>>? transactionsData}) {
    transactions = transactionsData ?? [];
  }
}

/// Fake DashboardProvider for testing
class FakeDashboardProvider extends ChangeNotifier implements DashboardProvider {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  Map<String, dynamic>? monthEndCheck;

  @override
  List<Map<String, dynamic>> budgetStatuses = [];

  @override
  dynamic creditBalance;

  @override
  List<Map<String, dynamic>> transactions = [];

  /// Test hook: set to observe when the widget actually calls load().
  void Function()? onLoad;

  @override
  Future<void> load() async {
    onLoad?.call();
  }

  FakeDashboardProvider({
    Map<String, dynamic>? monthEndCheckData,
    List<Map<String, dynamic>>? budgetStatusesData,
    dynamic creditBalanceData,
    List<Map<String, dynamic>>? transactionsData,
  }) {
    monthEndCheck = monthEndCheckData;
    budgetStatuses = budgetStatusesData ?? [];
    creditBalance = creditBalanceData;
    transactions = transactionsData ?? [];
  }
}

void main() {
  group('HomePage', () {
    late FakeDashboardProvider fakeDashboardProvider;

    setUp(() {
      fakeDashboardProvider = FakeDashboardProvider();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: fakeDashboardProvider as DashboardProvider,
          child: const HomePage(),
        ),
      );
    }

    group('UI elements', () {
      testWidgets('should display Scaffold with AppBar', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display Dashboard title in AppBar', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Dashboard'), findsWidgets);
      });

      testWidgets('should call DashboardProvider.load() once mounted', (WidgetTester tester) async {
        var loadCalled = false;
        fakeDashboardProvider = FakeDashboardProvider();
        fakeDashboardProvider.onLoad = () => loadCalled = true;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(loadCalled, isTrue);
      });
    });

    group('rendering', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('should render with basic Material design structure',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('with dashboard data', () {
      testWidgets(
        'should render when provider has month-end check data',
        (WidgetTester tester) async {
          fakeDashboardProvider = FakeDashboardProvider(
            monthEndCheckData: {
              'hdfc_reserve': 1000.0,
              'total_net_worth': 50000.0,
              'ICICI': {'expected_balance': 5000.0},
              'SBI': {'expected_balance': 3000.0},
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<DashboardProvider>.value(
                value: fakeDashboardProvider as DashboardProvider,
                child: const HomePage(),
              ),
            ),
          );

          expect(find.byType(HomePage), findsOneWidget);
          expect(find.text('Month-End Check'), findsOneWidget);
        },
      );

      testWidgets(
        'should render when provider has budget statuses',
        (WidgetTester tester) async {
          fakeDashboardProvider = FakeDashboardProvider(
            budgetStatusesData: [
              {'code': 'GROCERIES', 'name': 'Groceries', 'limit': 5000},
              {'code': 'TRANSPORT', 'name': 'Transport', 'limit': 2000},
              {'code': 'ENTERTAINMENT', 'name': 'Entertainment', 'limit': 3000},
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<DashboardProvider>.value(
                value: fakeDashboardProvider as DashboardProvider,
                child: const HomePage(),
              ),
            ),
          );

          expect(find.byType(HomePage), findsOneWidget);
        },
      );

      testWidgets(
        'should render when provider has credit balance',
        (WidgetTester tester) async {
          fakeDashboardProvider = FakeDashboardProvider(
            creditBalanceData: 12500,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<DashboardProvider>.value(
                value: fakeDashboardProvider as DashboardProvider,
                child: const HomePage(),
              ),
            ),
          );

          expect(find.byType(HomePage), findsOneWidget);
        },
      );

      testWidgets(
        'should render when provider has transactions',
        (WidgetTester tester) async {
          fakeDashboardProvider = FakeDashboardProvider(
            transactionsData: [
              {'id': 1, 'category': 'GROCERIES', 'amount': 500},
              {'id': 2, 'category': 'TRANSPORT', 'amount': 100},
              {'id': 3, 'category': 'ENTERTAINMENT', 'amount': 50},
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<DashboardProvider>.value(
                value: fakeDashboardProvider as DashboardProvider,
                child: const HomePage(),
              ),
            ),
          );

          expect(find.byType(HomePage), findsOneWidget);
        },
      );

      testWidgets(
        'should render with all dashboard data populated',
        (WidgetTester tester) async {
          fakeDashboardProvider = FakeDashboardProvider(
            monthEndCheckData: {
              'hdfc_reserve': 1000.0,
              'total_net_worth': 50000.0,
              'ICICI': {'expected_balance': 5000.0},
              'SBI': {'expected_balance': 3000.0},
            },
            budgetStatusesData: [
              {'code': 'GROCERIES', 'name': 'Groceries', 'limit': 5000},
              {'code': 'TRANSPORT', 'name': 'Transport', 'limit': 2000},
            ],
            creditBalanceData: 12500,
            transactionsData: [
              {'id': 1, 'category': 'GROCERIES', 'amount': 500},
              {'id': 2, 'category': 'TRANSPORT', 'amount': 100},
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<DashboardProvider>.value(
                value: fakeDashboardProvider as DashboardProvider,
                child: const HomePage(),
              ),
            ),
          );

          expect(find.byType(HomePage), findsOneWidget);
          expect(find.text('Dashboard'), findsWidgets);
        },
      );
    });

    group('state transitions', () {
      testWidgets('should remain rendered when loading', (WidgetTester tester) async {
        fakeDashboardProvider = FakeDashboardProvider();
        fakeDashboardProvider.isLoading = true;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DashboardProvider>.value(
              value: fakeDashboardProvider as DashboardProvider,
              child: const HomePage(),
            ),
          ),
        );

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should remain rendered when error occurs',
          (WidgetTester tester) async {
        fakeDashboardProvider = FakeDashboardProvider();
        fakeDashboardProvider.errorMessage = 'Failed to load dashboard data';

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DashboardProvider>.value(
              value: fakeDashboardProvider as DashboardProvider,
              child: const HomePage(),
            ),
          ),
        );

        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('basic page structure', () {
      testWidgets('should have proper Material scaffold structure',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final scaffoldFinder = find.byType(Scaffold);
        expect(scaffoldFinder, findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);
      });

      testWidgets('should have a scrollable content area',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('should show a Center/loading indicator while loading',
          (WidgetTester tester) async {
        fakeDashboardProvider = FakeDashboardProvider();
        fakeDashboardProvider.isLoading = true;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DashboardProvider>.value(
              value: fakeDashboardProvider as DashboardProvider,
              child: const HomePage(),
            ),
          ),
        );

        expect(find.byType(Center), findsWidgets);
      });

      testWidgets('should be a StatefulWidget (so it can trigger load() on mount)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(HomePage), findsOneWidget);
        final homePageWidget =
            find.byType(HomePage).evaluate().first.widget as HomePage;
        expect(homePageWidget, isA<StatefulWidget>());
      });
    });

    group('provider integration', () {
      testWidgets('should have access to DashboardProvider',
          (WidgetTester tester) async {
        fakeDashboardProvider = FakeDashboardProvider(
          monthEndCheckData: {'hdfc_reserve': 1000.0, 'total_net_worth': 50000.0},
          budgetStatusesData: [
            {'code': 'GROCERIES', 'name': 'Groceries', 'limit': 5000},
          ],
          creditBalanceData: 5000,
          transactionsData: [
            {'id': 1, 'category': 'GROCERIES', 'amount': 500},
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DashboardProvider>.value(
              value: fakeDashboardProvider as DashboardProvider,
              child: const HomePage(),
            ),
          ),
        );

        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('should render correctly with null provider data',
          (WidgetTester tester) async {
        fakeDashboardProvider = FakeDashboardProvider(
          monthEndCheckData: null,
          budgetStatusesData: [],
          creditBalanceData: null,
          transactionsData: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DashboardProvider>.value(
              value: fakeDashboardProvider as DashboardProvider,
              child: const HomePage(),
            ),
          ),
        );

        expect(find.byType(HomePage), findsOneWidget);
      });
    });
  });
}
