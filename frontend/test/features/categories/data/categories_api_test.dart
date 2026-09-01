import 'package:dio/dio.dart';
import 'package:finance_dashboard/features/categories/data/categories_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockDio extends Mock implements Dio {}

void main() {
  group('CategoriesApi', () {
    late MockDio mockDio;
    late CategoriesApi categoriesApi;

    setUp(() {
      mockDio = MockDio();
      categoriesApi = CategoriesApi(mockDio);
    });

    group('getCategories', () {
      test('should call GET /categories endpoint', () async {
        // Arrange - real backend response shape
        final backendResponse = {
          'categories': [
            {
              'code': 'food',
              'display_name': 'Food',
              'envelope': {
                'name': 'Food',
                'monthly_amount': 5000.0,
                'account_code': 'ICICI',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        await categoriesApi.getCategories();

        // Assert
        verify(() => mockDio.get('/categories')).called(1);
      });

      test('should return list of categories with correct structure', () async {
        // Arrange - real backend response shape
        final backendResponse = {
          'categories': [
            {
              'code': 'food',
              'display_name': 'Food',
              'envelope': {
                'name': 'Food',
                'monthly_amount': 5000.0,
                'account_code': 'ICICI',
              },
            },
            {
              'code': 'transport',
              'display_name': 'Transportation',
              'envelope': {
                'name': 'Transport',
                'monthly_amount': 2000.0,
                'account_code': 'SBI',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, equals(2));
        expect(result[0]['code'], equals('food'));
        expect(result[0]['display_name'], equals('Food'));
        expect(result[0]['envelope']['monthly_amount'], equals(5000.0));
        expect(result[1]['code'], equals('transport'));
      });

      test('should return empty list when no categories exist', () async {
        // Arrange - real backend response shape with empty list
        final backendResponse = {'categories': []};

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, equals(0));
      });

      test('should handle single category in response', () async {
        // Arrange - real backend response shape with one category
        final backendResponse = {
          'categories': [
            {
              'code': 'entertainment',
              'display_name': 'Entertainment',
              'envelope': {
                'name': 'Entertainment',
                'monthly_amount': 1000.0,
                'account_code': 'AXIS',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result.length, equals(1));
        expect(result[0]['code'], equals('entertainment'));
        expect(result[0]['envelope']['name'], equals('Entertainment'));
      });

      test('should preserve envelope data with category', () async {
        // Arrange - real backend response with full envelope data
        final backendResponse = {
          'categories': [
            {
              'code': 'shopping',
              'display_name': 'Shopping',
              'envelope': {
                'name': 'Shopping Budget',
                'monthly_amount': 3000.0,
                'account_code': 'ICICI',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result[0]['envelope'], isA<Map>());
        expect(result[0]['envelope']['name'], equals('Shopping Budget'));
        expect(result[0]['envelope']['monthly_amount'], equals(3000.0));
        expect(result[0]['envelope']['account_code'], equals('ICICI'));
      });

      test('should handle categories with zero monthly_amount', () async {
        // Arrange - real backend response with zero allocation
        final backendResponse = {
          'categories': [
            {
              'code': 'utilities',
              'display_name': 'Utilities',
              'envelope': {
                'name': 'Utilities Fund',
                'monthly_amount': 0.0,
                'account_code': 'SBI',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result[0]['envelope']['monthly_amount'], equals(0.0));
      });

      test('should handle large number of categories', () async {
        // Arrange - generate large list of categories
        final categories = List.generate(
          50,
          (index) => {
            'code': 'category_$index',
            'display_name': 'Category $index',
            'envelope': {
              'name': 'Envelope $index',
              'monthly_amount': (index * 100).toDouble(),
              'account_code': 'BANK_$index',
            },
          },
        );

        final backendResponse = {'categories': categories};

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert
        expect(result.length, equals(50));
        expect(result[0]['code'], equals('category_0'));
        expect(result[49]['code'], equals('category_49'));
      });

      test('should throw exception on connection timeout', () async {
        // Arrange
        when(
          () => mockDio.get('/categories'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/categories'),
            message: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => categoriesApi.getCategories(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 401 unauthorized', () async {
        // Arrange
        when(
          () => mockDio.get('/categories'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/categories'),
            response: Response(
              statusCode: 401,
              data: {'message': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/categories'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => categoriesApi.getCategories(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on 500 server error', () async {
        // Arrange
        when(
          () => mockDio.get('/categories'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/categories'),
            response: Response(
              statusCode: 500,
              data: {'message': 'Internal server error'},
              requestOptions: RequestOptions(path: '/categories'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => categoriesApi.getCategories(),
          throwsA(isA<Exception>()),
        );
      });

      test('should correctly unwrap real backend response shape', () async {
        // Arrange - real backend response structure
        final backendResponse = {
          'categories': [
            {
              'code': 'food',
              'display_name': 'Food & Dining',
              'envelope': {
                'name': 'Monthly Food Budget',
                'monthly_amount': 5000.0,
                'account_code': 'ICICI',
              },
            },
            {
              'code': 'transport',
              'display_name': 'Transportation',
              'envelope': {
                'name': 'Travel Fund',
                'monthly_amount': 2000.0,
                'account_code': 'SBI',
              },
            },
          ],
        };

        when(
          () => mockDio.get('/categories'),
        ).thenAnswer(
          (_) async => Response(
            data: backendResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await categoriesApi.getCategories();

        // Assert - verify non-empty list and correct structure
        expect(result, isNotEmpty);
        expect(result.length, equals(2));

        // Verify first category
        expect(result[0]['code'], equals('food'));
        expect(result[0]['display_name'], equals('Food & Dining'));
        expect(result[0]['envelope']['monthly_amount'], equals(5000.0));

        // Verify second category
        expect(result[1]['code'], equals('transport'));
        expect(result[1]['envelope']['account_code'], equals('SBI'));
      });
    });
  });
}
