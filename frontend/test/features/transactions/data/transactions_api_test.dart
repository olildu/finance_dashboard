import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('TransactionsApi', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('createTransaction', () {
      test('should call POST /transactions with correct payload', () async {
        // Arrange
        const categoryCode = 'food';
        const amount = 50.0;
        const reason = 'Lunch';
        final date = DateTime(2026, 9, 1);

        final responseData = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': reason,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockDio.post(
            '/transactions',
            data: {
              'category_code': categoryCode,
              'amount': amount,
              'reason': reason,
              'date': date.toIso8601String(),
            },
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        await api.createTransaction(
          categoryCode: categoryCode,
          amount: amount,
          reason: reason,
          date: date,
        );

        // Assert
        verify(
          () => mockDio.post(
            '/transactions',
            data: {
              'category_code': categoryCode,
              'amount': amount,
              'reason': reason,
              'date': date.toIso8601String(),
            },
          ),
        ).called(1);
      });

      test('should return transaction data on successful creation', () async {
        // Arrange
        const categoryCode = 'food';
        const amount = 50.0;
        const reason = 'Lunch';
        final date = DateTime(2026, 9, 1);

        final responseData = {
          'id': 1,
          'category_code': categoryCode,
          'amount': amount,
          'reason': reason,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockDio.post(
            '/transactions',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.createTransaction(
          categoryCode: categoryCode,
          amount: amount,
          reason: reason,
          date: date,
        );

        // Assert
        expect(result['id'], equals(1));
        expect(result['category_code'], equals(categoryCode));
        expect(result['amount'], equals(amount));
        expect(result['reason'], equals(reason));
        expect(result['is_overage'], equals(false));
      });

      test('should handle transaction without reason (optional)', () async {
        // Arrange
        const categoryCode = 'rent';
        const amount = 1000.0;
        final date = DateTime(2026, 9, 1);

        final responseData = {
          'id': 2,
          'category_code': categoryCode,
          'amount': amount,
          'reason': null,
          'date': date.toIso8601String(),
          'is_overage': false,
        };

        when(
          () => mockDio.post(
            '/transactions',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.createTransaction(
          categoryCode: categoryCode,
          amount: amount,
          date: date,
        );

        // Assert
        expect(result['reason'], isNull);
      });

      test('should throw exception on 400 status (bad request)', () async {
        // Arrange
        when(
          () => mockDio.post(
            '/transactions',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions'),
            response: Response(
              statusCode: 400,
              data: {'detail': 'Invalid category code'},
              requestOptions: RequestOptions(path: '/transactions'),
            ),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.createTransaction(
            categoryCode: 'invalid',
            amount: 50.0,
            date: DateTime.now(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.post(
            '/transactions',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/transactions'),
            message: 'Connection timeout',
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.createTransaction(
            categoryCode: 'food',
            amount: 50.0,
            date: DateTime.now(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 500 status', () async {
        // Arrange
        when(
          () => mockDio.post(
            '/transactions',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/transactions'),
            ),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.createTransaction(
            categoryCode: 'food',
            amount: 50.0,
            date: DateTime.now(),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getTransactions', () {
      test('should call GET /transactions endpoint', () async {
        // Arrange
        final responseData = [
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

        when(
          () => mockDio.get('/transactions'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        await api.getTransactions();

        // Assert
        verify(
          () => mockDio.get('/transactions'),
        ).called(1);
      });

      test('should return list of transactions on success', () async {
        // Arrange — backend returns TransactionListResponse: {"transactions": [...]}
        final responseData = {
          'transactions': [
            {
              'id': 1,
              'category_code': 'food',
              'amount': 50.0,
              'reason': 'Lunch',
              'date': '2026-09-01T12:00:00',
              'is_overage': false,
            },
          ],
        };

        when(
          () => mockDio.get('/transactions'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.getTransactions();

        // Assert
        expect(result, isA<List>());
        expect(result.length, equals(1));
        expect(result[0]['id'], equals(1));
        expect(result[0]['category_code'], equals('food'));
      });

      test('should return empty list when no transactions', () async {
        // Arrange
        when(
          () => mockDio.get('/transactions'),
        ).thenAnswer(
          (_) async => Response(
            data: [],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.getTransactions();

        // Assert
        expect(result, isEmpty);
      });

      test('should handle transactions with is_overage=true', () async {
        // Arrange — backend returns TransactionListResponse: {"transactions": [...]}
        final responseData = {
          'transactions': [
            {
              'id': 1,
              'category_code': 'food',
              'amount': 150.0,
              'reason': 'Overspent',
              'date': '2026-09-01T12:00:00',
              'is_overage': true,
            },
          ],
        };

        when(
          () => mockDio.get('/transactions'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.getTransactions();

        // Assert
        expect(result[0]['is_overage'], equals(true));
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.get('/transactions'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/transactions'),
            message: 'Connection timeout',
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.getTransactions(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 500 status', () async {
        // Arrange
        when(
          () => mockDio.get('/transactions'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/transactions'),
            ),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.getTransactions(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteTransaction', () {
      test('should call DELETE /transactions/{id} with correct ID', () async {
        // Arrange
        const transactionId = 1;

        when(
          () => mockDio.delete('/transactions/$transactionId'),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions/$transactionId'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        await api.deleteTransaction(transactionId);

        // Assert
        verify(
          () => mockDio.delete('/transactions/$transactionId'),
        ).called(1);
      });

      test('should return true on successful deletion', () async {
        // Arrange
        const transactionId = 1;

        when(
          () => mockDio.delete('/transactions/$transactionId'),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/transactions/$transactionId'),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act
        final result = await api.deleteTransaction(transactionId);

        // Assert
        expect(result, isTrue);
      });

      test('should throw exception on 404 status (not found)', () async {
        // Arrange
        const transactionId = 999;

        when(
          () => mockDio.delete('/transactions/$transactionId'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions/$transactionId'),
            response: Response(
              statusCode: 404,
              data: {'detail': 'Transaction not found'},
              requestOptions: RequestOptions(path: '/transactions/$transactionId'),
            ),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.deleteTransaction(transactionId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.delete(any()),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/transactions/1'),
            message: 'Connection timeout',
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.deleteTransaction(1),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 500 status', () async {
        // Arrange
        when(
          () => mockDio.delete(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/transactions/1'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/transactions/1'),
            ),
          ),
        );

        final api = TransactionsApi(mockDio);

        // Act & Assert
        expect(
          () => api.deleteTransaction(1),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
