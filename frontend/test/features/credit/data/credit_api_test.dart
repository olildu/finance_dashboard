import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/credit/data/credit_api.dart';

// Mock classes for testing
class MockDio extends Mock implements Dio {}

void main() {
  group('CreditApi', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('getBalance', () {
      test('should call GET /credit/balance endpoint', () async {
        // Arrange
        final responseData = {'balance': 250.50};

        when(
          () => mockDio.get('/credit/balance'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/balance'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        await creditApi.getBalance();

        // Assert
        verify(
          () => mockDio.get('/credit/balance'),
        ).called(1);
      });

      test('should return balance from response', () async {
        // Arrange
        const expectedBalance = 150.75;
        final responseData = {'balance': expectedBalance};

        when(
          () => mockDio.get('/credit/balance'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/balance'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        final result = await creditApi.getBalance();

        // Assert
        expect(result['balance'], equals(expectedBalance));
      });

      test('should parse decimal balance correctly', () async {
        // Arrange
        const expectedBalance = 999.99;
        final responseData = {'balance': expectedBalance};

        when(
          () => mockDio.get('/credit/balance'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/balance'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        final result = await creditApi.getBalance();

        // Assert
        expect(result['balance'], isA<num>());
        expect(result['balance'], equals(expectedBalance));
      });

      test('should throw exception on API failure with 401 status', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/balance'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/credit/balance'),
            response: Response(
              statusCode: 401,
              data: {'detail': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/credit/balance'),
            ),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getBalance(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/balance'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/credit/balance'),
            message: 'Connection timeout',
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getBalance(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on 500 server error', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/balance'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/credit/balance'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/credit/balance'),
            ),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getBalance(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getHistory', () {
      test('should call GET /credit/history endpoint', () async {
        // Arrange
        final responseData = {
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

        when(
          () => mockDio.get('/credit/history'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/history'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        await creditApi.getHistory();

        // Assert
        verify(
          () => mockDio.get('/credit/history'),
        ).called(1);
      });

      test('should return entries list from response', () async {
        // Arrange
        final responseData = {
          'entries': [
            {
              'id': '1',
              'month': '2024-09',
              'category_code': 'OVERAGE',
              'amount': 100.00,
              'entry_type': 'charge',
              'created_at': '2024-09-01T10:30:00Z',
            },
            {
              'id': '2',
              'month': '2024-08',
              'category_code': 'SETTLEMENT',
              'amount': 50.00,
              'entry_type': 'credit',
              'created_at': '2024-08-15T14:20:00Z',
            },
          ],
        };

        when(
          () => mockDio.get('/credit/history'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/history'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        final result = await creditApi.getHistory();

        // Assert
        expect(result['entries'], isA<List>());
        expect(result['entries'].length, equals(2));
      });

      test('should parse all entry fields correctly', () async {
        // Arrange
        final responseData = {
          'entries': [
            {
              'id': 'entry-123',
              'month': '2024-09',
              'category_code': 'OVERAGE',
              'amount': 75.50,
              'entry_type': 'charge',
              'created_at': '2024-09-10T15:45:00Z',
            },
          ],
        };

        when(
          () => mockDio.get('/credit/history'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/history'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        final result = await creditApi.getHistory();
        final entry = result['entries'][0];

        // Assert
        expect(entry['id'], equals('entry-123'));
        expect(entry['month'], equals('2024-09'));
        expect(entry['category_code'], equals('OVERAGE'));
        expect(entry['amount'], equals(75.50));
        expect(entry['entry_type'], equals('charge'));
        expect(entry['created_at'], equals('2024-09-10T15:45:00Z'));
      });

      test('should return empty entries list when no history', () async {
        // Arrange
        final responseData = {'entries': []};

        when(
          () => mockDio.get('/credit/history'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/credit/history'),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act
        final result = await creditApi.getHistory();

        // Assert
        expect(result['entries'], isEmpty);
      });

      test('should throw exception on API failure with 401 status', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/history'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/credit/history'),
            response: Response(
              statusCode: 401,
              data: {'detail': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/credit/history'),
            ),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getHistory(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/history'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/credit/history'),
            message: 'Connection timeout',
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getHistory(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on 500 server error', () async {
        // Arrange
        when(
          () => mockDio.get('/credit/history'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/credit/history'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/credit/history'),
            ),
          ),
        );

        final creditApi = CreditApi(mockDio);

        // Act & Assert
        expect(
          () => creditApi.getHistory(),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
