import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';

class MockTransactionsApi extends Mock implements TransactionsApi {}

void main() {
  group('TransactionsProvider', () {
    late MockTransactionsApi mockTransactionsApi;

    setUp(() {
      mockTransactionsApi = MockTransactionsApi();
    });

    group('initialization', () {
      test('should initialize with empty transactions list', () {
        // Act
        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Assert
        expect(provider.transactions, isEmpty);
      });

      test('should initialize with isLoading as false', () {
        // Act
        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Assert
        expect(provider.isLoading, false);
      });

      test('should initialize with errorMessage as null', () {
        // Act
        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Assert
        expect(provider.errorMessage, isNull);
      });
    });

    group('load', () {
      test('should set isLoading to true while loading', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        final loadFuture = provider.load();

        // Assert - isLoading should be true during load
        expect(provider.isLoading, true);

        await loadFuture;
      });

      test('should populate transactions list on successful load', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.load();

        // Assert
        expect(provider.transactions.length, equals(1));
        expect(provider.transactions[0]['id'], equals(1));
      });

      test('should set isLoading to false after successful load', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.load();

        // Assert
        expect(provider.isLoading, false);
      });

      test('should clear error message on successful load', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.load();

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on load failure', () async {
        // Arrange
        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenThrow(Exception('Failed to load transactions'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
      });

      test('should set isLoading to false on load failure', () async {
        // Arrange
        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenThrow(Exception('Failed to load transactions'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.isLoading, false);
      });

      test('should load empty list when no transactions', () async {
        // Arrange
        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[],
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.load();

        // Assert
        expect(provider.transactions, isEmpty);
      });
    });

    group('addTransaction', () {
      test('should call api.createTransaction with correct parameters', () async {
        // Arrange
        const categoryCode = 'food';
        const amount = 50.0;
        const reason = 'Lunch';
        final date = DateTime(2026, 9, 1);

        final createdTransaction = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': reason,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: categoryCode,
            amount: amount,
            reason: reason,
            date: date,
          ),
        ).thenAnswer(
          (_) async => createdTransaction,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.addTransaction(
          categoryCode: categoryCode,
          amount: amount,
          reason: reason,
          date: date,
        );

        // Assert
        verify(
          () => mockTransactionsApi.createTransaction(
            categoryCode: categoryCode,
            amount: amount,
            reason: reason,
            date: date,
          ),
        ).called(1);
      });

      test('should add transaction to list on success', () async {
        // Arrange
        const categoryCode = 'food';
        const amount = 50.0;
        final date = DateTime(2026, 9, 1);

        final createdTransaction = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': null,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: categoryCode,
            amount: amount,
            reason: null,
            date: date,
          ),
        ).thenAnswer(
          (_) async => createdTransaction,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.addTransaction(
          categoryCode: categoryCode,
          amount: amount,
          date: date,
        );

        // Assert
        expect(provider.transactions.length, equals(1));
        expect(provider.transactions[0]['id'], equals(1));
      });

      test('should show overage transaction in list with is_overage=true', () async {
        // Arrange - Create an overage transaction (exceeds budget)
        const categoryCode = 'food';
        const amount = 150.0; // Overage amount
        final date = DateTime(2026, 9, 1);

        final createdTransaction = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': 'Overspent on food',
          'date': date.toIso8601String(),
          'is_overage': true,
        };

        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: categoryCode,
            amount: amount,
            reason: 'Overspent on food',
            date: date,
          ),
        ).thenAnswer(
          (_) async => createdTransaction,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.addTransaction(
          categoryCode: categoryCode,
          amount: amount,
          reason: 'Overspent on food',
          date: date,
        );

        // Assert - Overage transaction should still be in the list
        expect(provider.transactions.length, equals(1));
        expect(provider.transactions[0]['is_overage'], equals(true));
      });

      test('should clear error message on successful add', () async {
        // Arrange
        const categoryCode = 'food';
        const amount = 50.0;
        final date = DateTime(2026, 9, 1);

        final createdTransaction = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': null,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: categoryCode,
            amount: amount,
            reason: null,
            date: date,
          ),
        ).thenAnswer(
          (_) async => createdTransaction,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.addTransaction(
          categoryCode: categoryCode,
          amount: amount,
          date: date,
        );

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on add failure', () async {
        // Arrange
        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: any(named: 'categoryCode'),
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
            date: any(named: 'date'),
          ),
        ).thenThrow(Exception('Failed to create transaction'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.addTransaction(
            categoryCode: 'food',
            amount: 50.0,
            date: DateTime.now(),
          );
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
      });

      test('should not add transaction on failure', () async {
        // Arrange
        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: any(named: 'categoryCode'),
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
            date: any(named: 'date'),
          ),
        ).thenThrow(Exception('Failed to create transaction'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.addTransaction(
            categoryCode: 'food',
            amount: 50.0,
            date: DateTime.now(),
          );
        } catch (_) {}

        // Assert
        expect(provider.transactions, isEmpty);
      });
    });

    group('deleteTransaction', () {
      test('should call api.deleteTransaction with correct ID', () async {
        // Arrange
        const transactionId = 1;

        when(
          () => mockTransactionsApi.deleteTransaction(transactionId),
        ).thenAnswer(
          (_) async => true,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.deleteTransaction(transactionId);

        // Assert
        verify(
          () => mockTransactionsApi.deleteTransaction(transactionId),
        ).called(1);
      });

      test('should remove transaction from list on successful deletion', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        when(
          () => mockTransactionsApi.deleteTransaction(1),
        ).thenAnswer(
          (_) async => true,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // First load the transactions
        await provider.load();
        expect(provider.transactions.length, equals(1));

        // Act - Delete the transaction
        await provider.deleteTransaction(1);

        // Assert
        expect(provider.transactions.length, equals(0));
      });

      test('should clear error message on successful deletion', () async {
        // Arrange
        when(
          () => mockTransactionsApi.deleteTransaction(1),
        ).thenAnswer(
          (_) async => true,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        await provider.deleteTransaction(1);

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on delete failure', () async {
        // Arrange
        when(
          () => mockTransactionsApi.deleteTransaction(any()),
        ).thenThrow(Exception('Failed to delete transaction'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.deleteTransaction(1);
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
      });

      test('should handle deletion of non-existent transaction', () async {
        // Arrange
        when(
          () => mockTransactionsApi.deleteTransaction(999),
        ).thenThrow(Exception('Transaction not found'));

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act
        try {
          await provider.deleteTransaction(999);
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
        expect(provider.transactions, isEmpty);
      });
    });

    group('state management', () {
      test('should notify listeners on transaction addition', () async {
        // Arrange
        final createdTransaction = {
          'id': 1,
          'category_code': 'food',
          'amount': 50.0,
          'reason': null,
          'date': DateTime.now().toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockTransactionsApi.createTransaction(
            categoryCode: any(named: 'categoryCode'),
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
            date: any(named: 'date'),
          ),
        ).thenAnswer(
          (_) async => createdTransaction,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        bool listenerCalled = false;
        provider.addListener(() {
          listenerCalled = true;
        });

        // Act
        await provider.addTransaction(
          categoryCode: 'food',
          amount: 50.0,
          date: DateTime.now(),
        );

        // Assert
        expect(listenerCalled, isTrue);
      });

      test('should maintain state across multiple operations', () async {
        // Arrange
        final transactionData = <Map<String, dynamic>>[
          {
            'id': 1,
            'category_code': 'food',
            'amount': 50.0,
            'reason': 'Lunch',
            'date': '2026-09-01T12:00:00',
            'is_overage': false,
          },
        ];

        when(
          () => mockTransactionsApi.getTransactions(),
        ).thenAnswer(
          (_) async => transactionData,
        );

        when(
          () => mockTransactionsApi.deleteTransaction(1),
        ).thenAnswer(
          (_) async => true,
        );

        final provider = TransactionsProvider(
          transactionsApi: mockTransactionsApi,
        );

        // Act - Load transactions
        await provider.load();
        expect(provider.transactions.length, equals(1));

        // Act - Delete transaction
        await provider.deleteTransaction(1);
        expect(provider.transactions.length, equals(0));

        // Assert
        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}
