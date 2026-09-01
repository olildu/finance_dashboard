import 'package:dio/dio.dart';
import 'package:finance_dashboard/features/budgets/data/budgets_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockDio extends Mock implements Dio {}

void main() {
  group('BudgetsApi', () {
    late MockDio mockDio;
    late BudgetsApi budgetsApi;

    setUp(() {
      mockDio = MockDio();
      budgetsApi = BudgetsApi(mockDio);
    });

    group('getStatus', () {
      test('should call GET /status endpoint', () async {
        // Arrange - real backend response shape from schema
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.0,
              'spent': 1200.0,
              'remaining': 3800.0,
              'days_left': 25,
              'allowance_per_day': 152.0,
              'burn_rate_per_day': 120.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        await budgetsApi.getStatus();

        // Assert
        verify(() => mockDio.get('/budgets/status')).called(1);
      });

      test('should return map with categories key', () async {
        // Arrange - real backend response shape
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.0,
              'spent': 1200.0,
              'remaining': 3800.0,
              'days_left': 25,
              'allowance_per_day': 152.0,
              'burn_rate_per_day': 120.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('categories'), isTrue);
      });

      test('should parse single category status correctly', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.0,
              'spent': 1200.0,
              'remaining': 3800.0,
              'days_left': 25,
              'allowance_per_day': 152.0,
              'burn_rate_per_day': 120.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'], isA<List>());
        expect(result['categories'].length, equals(1));
        expect(result['categories'][0]['category_code'], equals('food'));
        expect(result['categories'][0]['display_name'], equals('Food & Dining'));
        expect(result['categories'][0]['budget'], equals(5000.0));
        expect(result['categories'][0]['spent'], equals(1200.0));
        expect(result['categories'][0]['remaining'], equals(3800.0));
        expect(result['categories'][0]['days_left'], equals(25));
        expect(result['categories'][0]['allowance_per_day'], equals(152.0));
        expect(result['categories'][0]['burn_rate_per_day'], equals(120.0));
      });

      test('should parse multiple categories correctly', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.0,
              'spent': 1200.0,
              'remaining': 3800.0,
              'days_left': 25,
              'allowance_per_day': 152.0,
              'burn_rate_per_day': 120.0,
              'projected_runout_date': null,
            },
            {
              'category_code': 'transport',
              'display_name': 'Transportation',
              'budget': 2000.0,
              'spent': 800.0,
              'remaining': 1200.0,
              'days_left': 25,
              'allowance_per_day': 48.0,
              'burn_rate_per_day': 32.0,
              'projected_runout_date': '2024-10-15',
            },
            {
              'category_code': 'shopping',
              'display_name': 'Shopping',
              'budget': 3000.0,
              'spent': 0.0,
              'remaining': 3000.0,
              'days_left': 25,
              'allowance_per_day': 120.0,
              'burn_rate_per_day': 0.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'].length, equals(3));
        expect(result['categories'][0]['category_code'], equals('food'));
        expect(result['categories'][1]['category_code'], equals('transport'));
        expect(result['categories'][2]['category_code'], equals('shopping'));
        expect(result['categories'][1]['projected_runout_date'],
            equals('2024-10-15'));
      });

      test('should handle empty categories list', () async {
        // Arrange
        final backendResponse = {'categories': []};

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'], isA<List>());
        expect(result['categories'].length, equals(0));
      });

      test('should preserve all decimal values as floats', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.50,
              'spent': 1234.75,
              'remaining': 3765.75,
              'days_left': 25,
              'allowance_per_day': 150.63,
              'burn_rate_per_day': 123.79,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'][0]['budget'], equals(5000.50));
        expect(result['categories'][0]['spent'], equals(1234.75));
        expect(result['categories'][0]['allowance_per_day'], equals(150.63));
        expect(result['categories'][0]['burn_rate_per_day'], equals(123.79));
      });

      test('should handle category with zero spend', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'entertainment',
              'display_name': 'Entertainment',
              'budget': 1000.0,
              'spent': 0.0,
              'remaining': 1000.0,
              'days_left': 25,
              'allowance_per_day': 40.0,
              'burn_rate_per_day': 0.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'][0]['spent'], equals(0.0));
        expect(result['categories'][0]['burn_rate_per_day'], equals(0.0));
        expect(result['categories'][0]['projected_runout_date'], isNull);
      });

      test('should handle category with overspend', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Food & Dining',
              'budget': 5000.0,
              'spent': 6000.0,
              'remaining': 0.0,
              'days_left': 25,
              'allowance_per_day': 0.0,
              'burn_rate_per_day': 240.0,
              'projected_runout_date': '2024-09-05',
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'][0]['remaining'], equals(0.0));
        expect(result['categories'][0]['allowance_per_day'], equals(0.0));
        expect(result['categories'][0]['projected_runout_date'], isNotNull);
      });

      test('should handle projected_runout_date as null', () async {
        // Arrange
        final backendResponse = {
          'categories': [
            {
              'category_code': 'utilities',
              'display_name': 'Utilities',
              'budget': 1500.0,
              'spent': 300.0,
              'remaining': 1200.0,
              'days_left': 25,
              'allowance_per_day': 48.0,
              'burn_rate_per_day': 12.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();

        // Assert
        expect(result['categories'][0]['projected_runout_date'], isNull);
      });

      test('should handle all category fields together', () async {
        // Arrange - comprehensive real backend response
        final backendResponse = {
          'categories': [
            {
              'category_code': 'travel_party',
              'display_name': 'Travel & Party Outside',
              'budget': 10000.0,
              'spent': 3500.0,
              'remaining': 6500.0,
              'days_left': 20,
              'allowance_per_day': 325.0,
              'burn_rate_per_day': 175.0,
              'projected_runout_date': '2024-10-08',
            },
          ],
        };

        when(
          () => mockDio.get('/budgets/status'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/budgets/status'),
          ),
        );

        // Act
        final result = await budgetsApi.getStatus();
        final category = result['categories'][0];

        // Assert - verify all fields present and correct
        expect(category['category_code'], equals('travel_party'));
        expect(category['display_name'], equals('Travel & Party Outside'));
        expect(category['budget'], equals(10000.0));
        expect(category['spent'], equals(3500.0));
        expect(category['remaining'], equals(6500.0));
        expect(category['days_left'], equals(20));
        expect(category['allowance_per_day'], equals(325.0));
        expect(category['burn_rate_per_day'], equals(175.0));
        expect(category['projected_runout_date'], equals('2024-10-08'));
      });

      test('should throw exception on connection timeout', () async {
        // Arrange
        when(
          () => mockDio.get('/budgets/status'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/budgets/status'),
            message: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => budgetsApi.getStatus(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 401 unauthorized', () async {
        // Arrange
        when(
          () => mockDio.get('/budgets/status'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/budgets/status'),
            response: Response(
              statusCode: 401,
              data: {'message': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/budgets/status'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => budgetsApi.getStatus(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 500 server error', () async {
        // Arrange
        when(
          () => mockDio.get('/budgets/status'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/budgets/status'),
            response: Response(
              statusCode: 500,
              data: {'message': 'Internal server error'},
              requestOptions: RequestOptions(path: '/budgets/status'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => budgetsApi.getStatus(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
