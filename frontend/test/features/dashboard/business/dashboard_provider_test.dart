import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/dashboard/business/dashboard_provider.dart';

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

  Future<void> Function()? _loadImpl;

  FakeAccountsProvider({Future<void> Function()? loadImpl})
      : _loadImpl = loadImpl ?? (() => Future.value());

  @override
  Future<void> load() async {
    return _loadImpl!();
  }

  void setMonthEndCheck(Map<String, dynamic>? data) {
    monthEndCheck = data;
    notifyListeners();
  }

  void setLoadError(Exception exception) {
    _loadImpl = () => Future.error(exception);
  }

  void setLoadDelay(Duration delay) {
    _loadImpl = () async {
      isLoading = true;
      notifyListeners();
      await Future.delayed(delay);
      isLoading = false;
      notifyListeners();
    };
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

  Future<void> Function()? _loadImpl;

  FakeBudgetsProvider({Future<void> Function()? loadImpl})
      : _loadImpl = loadImpl ?? (() => Future.value());

  @override
  Future<void> load({bool forceRefresh = false}) async {
    return _loadImpl!();
  }

  void setCategories(List<Map<String, dynamic>> data) {
    categories = data;
    notifyListeners();
  }

  void setLoadError(Exception exception) {
    _loadImpl = () => Future.error(exception);
  }

  void setLoadDelay(Duration delay) {
    _loadImpl = () async {
      isLoading = true;
      notifyListeners();
      await Future.delayed(delay);
      isLoading = false;
      notifyListeners();
    };
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

  Future<void> Function()? _loadImpl;

  FakeCreditProvider({Future<void> Function()? loadImpl})
      : _loadImpl = loadImpl ?? (() => Future.value());

  @override
  Future<void> load({bool forceRefresh = false}) async {
    return _loadImpl!();
  }

  void setBalance(dynamic data) {
    balance = data;
    notifyListeners();
  }

  void setLoadError(Exception exception) {
    _loadImpl = () => Future.error(exception);
  }

  void setLoadDelay(Duration delay) {
    _loadImpl = () async {
      isLoading = true;
      notifyListeners();
      await Future.delayed(delay);
      isLoading = false;
      notifyListeners();
    };
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

  Future<void> Function()? _loadImpl;

  FakeTransactionsProvider({Future<void> Function()? loadImpl})
      : _loadImpl = loadImpl ?? (() => Future.value());

  @override
  Future<void> load() async {
    return _loadImpl!();
  }

  void setTransactions(List<Map<String, dynamic>> data) {
    transactions = data;
    notifyListeners();
  }

  void setLoadError(Exception exception) {
    _loadImpl = () => Future.error(exception);
  }

  void setLoadDelay(Duration delay) {
    _loadImpl = () async {
      isLoading = true;
      notifyListeners();
      await Future.delayed(delay);
      isLoading = false;
      notifyListeners();
    };
  }

  @override
  Future<void> addTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(int transactionId) {
    throw UnimplementedError();
  }
}

void main() {
  group('DashboardProvider', () {
    late FakeAccountsProvider fakeAccountsProvider;
    late FakeBudgetsProvider fakeBudgetsProvider;
    late FakeCreditProvider fakeCreditProvider;
    late FakeTransactionsProvider fakeTransactionsProvider;

    setUp(() {
      fakeAccountsProvider = FakeAccountsProvider();
      fakeBudgetsProvider = FakeBudgetsProvider();
      fakeCreditProvider = FakeCreditProvider();
      fakeTransactionsProvider = FakeTransactionsProvider();
    });

    group('initialization', () {
      test('should initialize with all providers', () {
        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });

      test('should initialize with empty data from sub-providers', () {
        fakeAccountsProvider.setMonthEndCheck(null);
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.monthEndCheck, isNull);
        expect(provider.budgetStatuses, isEmpty);
        expect(provider.creditBalance, isNull);
        expect(provider.transactions, isEmpty);
      });
    });

    group('load', () {
      test('should load data from all four providers in parallel', () async {
        final monthEndData = {
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        };
        final categories = [
          {'code': 'GROCERIES', 'name': 'Groceries', 'limit': 5000},
          {'code': 'TRANSPORT', 'name': 'Transport', 'limit': 2000},
        ];
        final transactions = [
          {'id': 1, 'category': 'GROCERIES', 'amount': 500},
          {'id': 2, 'category': 'TRANSPORT', 'amount': 100},
        ];

        fakeAccountsProvider.setMonthEndCheck(monthEndData);
        fakeBudgetsProvider.setCategories(categories);
        fakeCreditProvider.setBalance(5000);
        fakeTransactionsProvider.setTransactions(transactions);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.monthEndCheck, equals(monthEndData));
        expect(provider.budgetStatuses, equals(categories));
        expect(provider.creditBalance, equals(5000));
        expect(provider.transactions, equals(transactions));
      });

      test('should set isLoading to true during load', () async {
        // Add delays to all providers to keep loading state true
        fakeAccountsProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeBudgetsProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeCreditProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeTransactionsProvider.setLoadDelay(const Duration(milliseconds: 50));

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        final loadFuture = provider.load();
        // Check that isLoading is true shortly after calling load
        await Future.delayed(const Duration(milliseconds: 10));
        expect(provider.isLoading, isTrue);

        await loadFuture;
      });

      test('should set isLoading to false after successful load', () async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.isLoading, isFalse);
      });

      test('should clear error message on successful load', () async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNull);
      });

      test('should handle error from AccountsProvider gracefully', () async {
        fakeAccountsProvider.setLoadError(Exception('Network error'));
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should handle error from BudgetsProvider gracefully', () async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });
        fakeBudgetsProvider.setLoadError(Exception('Budget service error'));
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should handle error from CreditProvider gracefully', () async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setLoadError(Exception('Credit service error'));
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should handle error from TransactionsProvider gracefully', () async {
        fakeAccountsProvider.setMonthEndCheck({
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        });
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setLoadError(Exception('Transactions service error'));

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should handle multiple provider failures', () async {
        fakeAccountsProvider.setLoadError(Exception('Accounts error'));
        fakeBudgetsProvider.setLoadError(Exception('Budgets error'));
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });
    });

    group('getters', () {
      test('monthEndCheck should return AccountsProvider data', () {
        final monthEndData = {
          'hdfc_reserve': 1500.0,
          'total_net_worth': 75000.0,
        };
        fakeAccountsProvider.setMonthEndCheck(monthEndData);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.monthEndCheck, equals(monthEndData));
      });

      test('budgetStatuses should return BudgetsProvider categories', () {
        final categories = [
          {'code': 'GROCERIES', 'name': 'Groceries', 'limit': 5000},
          {'code': 'TRANSPORT', 'name': 'Transport', 'limit': 2000},
          {'code': 'ENTERTAINMENT', 'name': 'Entertainment', 'limit': 3000},
        ];
        fakeBudgetsProvider.setCategories(categories);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.budgetStatuses, equals(categories));
        expect(provider.budgetStatuses.length, equals(3));
      });

      test('creditBalance should return CreditProvider balance', () {
        fakeCreditProvider.setBalance(12500);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.creditBalance, equals(12500));
      });

      test('transactions should return TransactionsProvider transactions', () {
        final transactions = [
          {'id': 1, 'category': 'GROCERIES', 'amount': 500},
          {'id': 2, 'category': 'TRANSPORT', 'amount': 100},
          {'id': 3, 'category': 'ENTERTAINMENT', 'amount': 50},
        ];
        fakeTransactionsProvider.setTransactions(transactions);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.transactions, equals(transactions));
        expect(provider.transactions.length, equals(3));
      });

      test('should expose all composed data simultaneously', () {
        final monthEndData = {
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        };
        final categories = [
          {'code': 'GROCERIES', 'name': 'Groceries'},
        ];
        final transactions = [
          {'id': 1, 'amount': 500},
        ];

        fakeAccountsProvider.setMonthEndCheck(monthEndData);
        fakeBudgetsProvider.setCategories(categories);
        fakeCreditProvider.setBalance(5000);
        fakeTransactionsProvider.setTransactions(transactions);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        expect(provider.monthEndCheck, isNotNull);
        expect(provider.budgetStatuses, isNotEmpty);
        expect(provider.creditBalance, isNotNull);
        expect(provider.transactions, isNotEmpty);
      });
    });

    group('state notifications', () {
      test('should notify listeners when load starts and ends', () async {
        var notificationCount = 0;

        fakeAccountsProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeBudgetsProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeCreditProvider.setLoadDelay(const Duration(milliseconds: 50));
        fakeTransactionsProvider.setLoadDelay(const Duration(milliseconds: 50));

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        provider.addListener(() {
          notificationCount++;
        });

        await provider.load();

        // Should notify at least twice (once for start, once for end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('should notify listeners on error', () async {
        var notificationCount = 0;

        fakeAccountsProvider.setLoadError(Exception('Test error'));
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        provider.addListener(() {
          notificationCount++;
        });

        await provider.load();

        expect(notificationCount, greaterThan(0));
        expect(provider.errorMessage, isNotNull);
      });
    });

    group('error extraction', () {
      test('should extract error message from Exception', () async {
        fakeAccountsProvider.setLoadError(Exception('Network timeout'));
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Network timeout'));
      });

      test('should handle error with custom message', () async {
        fakeAccountsProvider.setLoadError(Exception('Custom error message'));
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        await provider.load();

        expect(provider.errorMessage, contains('Custom error message'));
      });
    });

    group('concurrent loads', () {
      test('should handle multiple concurrent load calls', () async {
        fakeAccountsProvider.setMonthEndCheck({'hdfc_reserve': 1000.0});
        fakeBudgetsProvider.setCategories([]);
        fakeCreditProvider.setBalance(null);
        fakeTransactionsProvider.setTransactions([]);

        final provider = DashboardProvider(
          accountsProvider: fakeAccountsProvider,
          budgetsProvider: fakeBudgetsProvider,
          creditProvider: fakeCreditProvider,
          transactionsProvider: fakeTransactionsProvider,
        );

        // Trigger multiple loads concurrently
        final results = await Future.wait([
          provider.load(),
          provider.load(),
          provider.load(),
        ]);

        expect(results.length, equals(3));
        expect(provider.isLoading, isFalse);
      });
    });
  });
}
