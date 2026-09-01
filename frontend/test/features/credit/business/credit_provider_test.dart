import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/credit/data/credit_api.dart';

class MockCreditApi extends Mock implements CreditApi {}

void main() {
  group('CreditProvider', () {
    late MockCreditApi mockCreditApi;

    setUp(() {
      mockCreditApi = MockCreditApi();
    });

    group('initialization', () {
      test('should initialize with null balance', () {
        // Act
        final provider = CreditProvider(creditApi: mockCreditApi);

        // Assert
        expect(provider.balance, isNull);
      });

      test('should initialize with empty history', () {
        // Act
        final provider = CreditProvider(creditApi: mockCreditApi);

        // Assert
        expect(provider.history, isEmpty);
      });

      test('should initialize with isLoading as false', () {
        // Act
        final provider = CreditProvider(creditApi: mockCreditApi);

        // Assert
        expect(provider.isLoading, false);
      });

      test('should initialize with errorMessage as null', () {
        // Act
        final provider = CreditProvider(creditApi: mockCreditApi);

        // Assert
        expect(provider.errorMessage, isNull);
      });
    });

    group('load', () {
      test('should fetch balance and history from API', () async {
        // Arrange
        final balanceResponse = {'balance': 100.50};
        final historyResponse = {
          'entries': [
            {
              'id': '1',
              'month': '2024-09',
              'category_code': 'OVERAGE',
              'amount': 50.00,
              'entry_type': 'charge',
              'created_at': '2024-09-01T10:30:00Z',
            },
          ],
        };

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        expect(provider.balance, equals(100.50));
        expect(provider.history, isNotEmpty);
        expect(provider.history.length, equals(1));
      });

      test('should populate balance correctly', () async {
        // Arrange
        const expectedBalance = 250.75;
        final balanceResponse = {'balance': expectedBalance};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        expect(provider.balance, equals(expectedBalance));
      });

      test('should populate history entries correctly', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {
          'entries': [
            {
              'id': 'entry-1',
              'month': '2024-09',
              'category_code': 'OVERAGE',
              'amount': 75.00,
              'entry_type': 'charge',
              'created_at': '2024-09-10T15:45:00Z',
            },
            {
              'id': 'entry-2',
              'month': '2024-08',
              'category_code': 'SETTLEMENT',
              'amount': 50.00,
              'entry_type': 'credit',
              'created_at': '2024-08-15T14:20:00Z',
            },
          ],
        };

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        expect(provider.history.length, equals(2));
        expect(provider.history[0]['id'], equals('entry-1'));
        expect(provider.history[1]['id'], equals('entry-2'));
      });

      test('should set isLoading to true during load', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act & Assert - check that isLoading changes
        final loadFuture = provider.load();
        expect(provider.isLoading, true);

        await loadFuture;
        expect(provider.isLoading, false);
      });

      test('should set isLoading to false after successful load', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        expect(provider.isLoading, false);
      });

      test('should clear error message on successful load', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on API failure', () async {
        // Arrange
        when(() => mockCreditApi.getBalance()).thenThrow(
          Exception('API Error: Network timeout'),
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('API Error'));
      });

      test('should set isLoading to false on error', () async {
        // Arrange
        when(() => mockCreditApi.getBalance()).thenThrow(
          Exception('Network error'),
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.isLoading, false);
      });

      test('should handle server errors gracefully', () async {
        // Arrange
        when(() => mockCreditApi.getBalance()).thenThrow(
          Exception('Server Error: 500 Internal Server Error'),
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
      });

      test('should call getBalance and getHistory APIs', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        await provider.load();

        // Assert
        verify(() => mockCreditApi.getBalance()).called(1);
        verify(() => mockCreditApi.getHistory()).called(1);
      });

      test('should use cached data when forceRefresh is false', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act - load first time
        await provider.load(forceRefresh: false);
        final firstBalance = provider.balance;

        // Act - load second time without force refresh
        await provider.load(forceRefresh: false);

        // Assert - balance should be the same
        expect(provider.balance, equals(firstBalance));
      });

      test('should refresh data when forceRefresh is true', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act - load first time
        await provider.load(forceRefresh: false);

        // Act - load with force refresh
        await provider.load(forceRefresh: true);

        // Assert - API should be called again
        verify(() => mockCreditApi.getBalance()).called(2);
      });

      test('should maintain state across multiple concurrent loads',
          () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act - call load multiple times concurrently
        await Future.wait([
          provider.load(),
          provider.load(),
        ]);

        // Assert
        expect(provider.balance, equals(100.0));
        expect(provider.isLoading, false);
      });
    });

    group('state transitions', () {
      test('should transition from loading to loaded state', () async {
        // Arrange
        final balanceResponse = {'balance': 100.0};
        final historyResponse = {'entries': []};

        when(() => mockCreditApi.getBalance()).thenAnswer(
          (_) async => balanceResponse,
        );

        when(() => mockCreditApi.getHistory()).thenAnswer(
          (_) async => historyResponse,
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        final loadFuture = provider.load();

        // Assert - isLoading should be true
        expect(provider.isLoading, true);

        await loadFuture;

        // Assert - isLoading should be false
        expect(provider.isLoading, false);
        expect(provider.balance, isNotNull);
      });

      test('should transition to error state on failure', () async {
        // Arrange
        when(() => mockCreditApi.getBalance()).thenThrow(
          Exception('Load failed'),
        );

        final provider = CreditProvider(creditApi: mockCreditApi);

        // Act
        try {
          await provider.load();
        } catch (_) {}

        // Assert
        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNotNull);
      });
    });
  });
}
