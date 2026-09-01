import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_dashboard/features/accounts/data/accounts_api.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';

// Simple mock implementation
class FakeAccountsApi implements AccountsApi {
  late Future<List<Map<String, dynamic>>> Function() _getAccountsImpl;
  late Future<Map<String, dynamic>> Function() _getMonthEndCheckImpl;

  FakeAccountsApi({
    Future<List<Map<String, dynamic>>> Function()? getAccountsImpl,
    Future<Map<String, dynamic>> Function()? getMonthEndCheckImpl,
  }) {
    _getAccountsImpl = getAccountsImpl ?? () => Future.value([]);
    _getMonthEndCheckImpl = getMonthEndCheckImpl ?? () => Future.value({});
  }

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getAccounts() => _getAccountsImpl();

  @override
  Future<Map<String, dynamic>> getMonthEndCheck() => _getMonthEndCheckImpl();

  void setGetAccounts(Future<List<Map<String, dynamic>>> Function() impl) {
    _getAccountsImpl = impl;
  }

  void setGetMonthEndCheck(Future<Map<String, dynamic>> Function() impl) {
    _getMonthEndCheckImpl = impl;
  }

  void throwOnGetAccounts(Exception exception) {
    _getAccountsImpl = () => Future.error(exception);
  }

  void throwOnGetMonthEndCheck(Exception exception) {
    _getMonthEndCheckImpl = () => Future.error(exception);
  }
}

void main() {
  group('AccountsProvider', () {
    late FakeAccountsApi fakeAccountsApi;

    setUp(() {
      fakeAccountsApi = FakeAccountsApi();
    });

    group('initialization', () {
      test('should initialize with empty accounts list', () {
        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        expect(provider.accounts, isEmpty);
        expect(provider.monthEndCheck, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });

      test('should initialize isLoading as false', () {
        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        expect(provider.isLoading, isFalse);
      });

      test('should initialize errorMessage as null', () {
        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        expect(provider.errorMessage, isNull);
      });

      test('should initialize monthEndCheck as null', () {
        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        expect(provider.monthEndCheck, isNull);
      });
    });

    group('load', () {
      test('should successfully load accounts and month-end check data',
          () async {
        final accountsData = [
          {'id': 1, 'code': 'ICICI', 'display_name': 'ICICI Bank', 'kind': 'bank', 'fixed_amount': null},
          {'id': 2, 'code': 'SBI', 'display_name': 'SBI', 'kind': 'bank', 'fixed_amount': null},
        ];
        final monthEndData = {
          'ICICI': {'expected_balance': 5000.0},
          'SBI': {'expected_balance': 3000.0},
          'SLICE': {'expected_balance': 2000.0},
          'hdfc_reserve': 1000.0,
          'total_net_worth': 50000.0,
        };

        fakeAccountsApi.setGetAccounts(() => Future.value(accountsData));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value(monthEndData));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.accounts, equals(accountsData));
        expect(provider.monthEndCheck, equals(monthEndData));
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });

      test('should set isLoading to true during load', () async {
        fakeAccountsApi.setGetAccounts(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return [];
        });
        fakeAccountsApi.setGetMonthEndCheck(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return {};
        });

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        final loadFuture = provider.load();
        await Future.delayed(const Duration(milliseconds: 5));
        expect(provider.isLoading, isTrue);
        await loadFuture;
        expect(provider.isLoading, isFalse);
      });

      test('should clear error message on successful load', () async {
        final accountsData = [{'id': 1, 'code': 'ICICI', 'display_name': 'ICICI Bank', 'kind': 'bank', 'fixed_amount': null}];
        final monthEndData = {'ICICI': {'expected_balance': 5000.0}, 'hdfc_reserve': 1000.0, 'total_net_worth': 50000.0};

        fakeAccountsApi.setGetAccounts(() => Future.value(accountsData));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value(monthEndData));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on API failure', () async {
        fakeAccountsApi.throwOnGetAccounts(Exception('Network error'));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.accounts, isEmpty);
      });

      test('should handle getAccounts failure gracefully', () async {
        fakeAccountsApi.throwOnGetAccounts(Exception('Network error'));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value({}));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should handle getMonthEndCheck failure gracefully', () async {
        final accountsData = [{'id': 1, 'code': 'ICICI', 'display_name': 'ICICI Bank', 'kind': 'bank', 'fixed_amount': null}];

        fakeAccountsApi.setGetAccounts(() => Future.value(accountsData));
        fakeAccountsApi.throwOnGetMonthEndCheck(Exception('Server error'));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('should populate accounts list on successful load', () async {
        final accountsData = [
          {'id': 1, 'code': 'ICICI', 'display_name': 'ICICI Bank', 'kind': 'bank', 'fixed_amount': null},
          {'id': 2, 'code': 'SBI', 'display_name': 'SBI', 'kind': 'bank', 'fixed_amount': null},
        ];
        final monthEndData = {'hdfc_reserve': 1000.0, 'total_net_worth': 50000.0};

        fakeAccountsApi.setGetAccounts(() => Future.value(accountsData));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value(monthEndData));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.accounts.length, equals(2));
        expect(provider.accounts[0]['code'], equals('ICICI'));
      });

      test('should populate monthEndCheck data on successful load', () async {
        final monthEndData = {'ICICI': {'expected_balance': 5000.0}, 'hdfc_reserve': 1500.0, 'total_net_worth': 75000.0};

        fakeAccountsApi.setGetAccounts(() => Future.value([]));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value(monthEndData));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.monthEndCheck, equals(monthEndData));
        expect(provider.monthEndCheck!['hdfc_reserve'], equals(1500.0));
        expect(provider.monthEndCheck!['total_net_worth'], equals(75000.0));
      });

      test('should handle empty accounts list', () async {
        final monthEndData = {'hdfc_reserve': 0.0, 'total_net_worth': 0.0};

        fakeAccountsApi.setGetAccounts(() => Future.value([]));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value(monthEndData));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.accounts, isEmpty);
        expect(provider.monthEndCheck!['hdfc_reserve'], equals(0.0));
      });

      test('should set isLoading to false on load completion', () async {
        fakeAccountsApi.setGetAccounts(() => Future.value([]));
        fakeAccountsApi.setGetMonthEndCheck(() => Future.value({}));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.isLoading, isFalse);
      });
    });

    group('error handling', () {
      test('should handle network timeout errors', () async {
        fakeAccountsApi.throwOnGetAccounts(Exception('Network timeout'));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
      });

      test('should handle unauthorized (401) errors', () async {
        fakeAccountsApi.throwOnGetAccounts(Exception('Unauthorized'));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
      });

      test('should handle server (500) errors', () async {
        fakeAccountsApi.throwOnGetAccounts(Exception('Server error'));

        final provider = AccountsProvider(accountsApi: fakeAccountsApi);
        await provider.load();

        expect(provider.errorMessage, isNotNull);
      });
    });
  });
}
