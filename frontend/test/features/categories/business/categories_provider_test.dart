import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/categories/business/categories_provider.dart';
import 'package:finance_dashboard/features/categories/data/categories_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockCategoriesApi extends Mock implements CategoriesApi {}

void main() {
  group('CategoriesProvider', () {
    late MockCategoriesApi mockCategoriesApi;
    late CategoriesProvider categoriesProvider;

    setUp(() {
      mockCategoriesApi = MockCategoriesApi();
      categoriesProvider = CategoriesProvider(categoriesApi: mockCategoriesApi);
    });

    group('initialization', () {
      test('should initialize with empty categories list', () {
        // Arrange & Act & Assert
        expect(categoriesProvider.categories, isEmpty);
      });

      test('should initialize isLoading as false', () {
        // Arrange & Act & Assert
        expect(categoriesProvider.isLoading, isFalse);
      });

      test('should initialize errorMessage as null', () {
        // Arrange & Act & Assert
        expect(categoriesProvider.errorMessage, isNull);
      });

      test('should not call API on initialization', () {
        // Arrange & Act & Assert
        verifyNever(() => mockCategoriesApi.getCategories());
      });
    });

    group('load', () {
      test('should successfully load categories', () async {
        // Arrange
        final categoriesData = [
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
              'name': 'Transportation Fund',
              'monthly_amount': 2000.0,
              'account_code': 'SBI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, equals(categoriesData));
        expect(categoriesProvider.isLoading, isFalse);
        expect(categoriesProvider.errorMessage, isNull);
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });

      test('should set isLoading to true during load', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async {
          expect(categoriesProvider.isLoading, isTrue);
          return [];
        });

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.isLoading, isFalse);
      });

      test('should clear error message on successful load', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'test',
            'display_name': 'Test Category',
            'envelope': {
              'name': 'Test Envelope',
              'monthly_amount': 1000.0,
              'account_code': 'AXIS',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNull);
      });

      test('should set errorMessage and keep isLoading false on API failure',
          () async {
        // Arrange
        const errorMessage = 'Failed to load categories';

        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception(errorMessage));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
        expect(categoriesProvider.isLoading, isFalse);
        expect(categoriesProvider.categories, isEmpty);
      });

      test('should populate categories list on successful load', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Food',
            'envelope': {
              'name': 'Food Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
          {
            'code': 'transport',
            'display_name': 'Transport',
            'envelope': {
              'name': 'Transport Budget',
              'monthly_amount': 2000.0,
              'account_code': 'SBI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories.length, equals(2));
        expect(categoriesProvider.categories[0]['code'], equals('food'));
        expect(categoriesProvider.categories[1]['code'], equals('transport'));
      });

      test('should handle empty categories list', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => []);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, isEmpty);
        expect(categoriesProvider.errorMessage, isNull);
      });

      test('should set isLoading to false on load completion', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => []);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.isLoading, isFalse);
      });

      test('should handle network timeout errors gracefully', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Network timeout'));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
        expect(categoriesProvider.errorMessage, contains('timeout'));
      });

      test('should handle 401 unauthorized errors', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Unauthorized (HTTP 401)'));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
      });

      test('should handle server (500) errors gracefully', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Server error (HTTP 500)'));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
      });

      test('should handle invalid response gracefully', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Invalid response'));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
      });
    });

    group('caching behavior', () {
      test('should cache categories and not call API twice on consecutive loads',
          () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Food',
            'envelope': {
              'name': 'Food Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        final firstLoadCategories = categoriesProvider.categories;
        await categoriesProvider.load();
        final secondLoadCategories = categoriesProvider.categories;

        // Assert
        expect(firstLoadCategories, equals(secondLoadCategories));
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });

      test('should return cached categories on second load without API call',
          () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'entertainment',
            'display_name': 'Entertainment',
            'envelope': {
              'name': 'Entertainment Budget',
              'monthly_amount': 1000.0,
              'account_code': 'HDFC',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, equals(categoriesData));
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });

      test('should use cache across multiple sequential loads', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'shopping',
            'display_name': 'Shopping',
            'envelope': {
              'name': 'Shopping Budget',
              'monthly_amount': 3000.0,
              'account_code': 'SBI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load();
        await categoriesProvider.load();

        // Assert
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });

      test('should bypass cache when forceRefresh is true', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'utilities',
            'display_name': 'Utilities',
            'envelope': {
              'name': 'Utilities Budget',
              'monthly_amount': 1500.0,
              'account_code': 'AXIS',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load(forceRefresh: true);

        // Assert
        verify(() => mockCategoriesApi.getCategories()).called(2);
      });

      test('should refetch data when forceRefresh is true', () async {
        // Arrange
        final initialData = [
          {
            'code': 'cat_1',
            'display_name': 'Old Name',
            'envelope': {
              'name': 'Old Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        final updatedData = [
          {
            'code': 'cat_1',
            'display_name': 'Updated Name',
            'envelope': {
              'name': 'Updated Budget',
              'monthly_amount': 6000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => initialData);

        // Act
        await categoriesProvider.load();
        expect(categoriesProvider.categories[0]['display_name'], equals('Old Name'));

        // Setup second response
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => updatedData);

        await categoriesProvider.load(forceRefresh: true);

        // Assert
        expect(categoriesProvider.categories[0]['display_name'], equals('Updated Name'));
      });

      test('should cache empty categories list', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => []);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, isEmpty);
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });

      test('should not cache data when load fails', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'healthcare',
            'display_name': 'Healthcare',
            'envelope': {
              'name': 'Health Budget',
              'monthly_amount': 2000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Network error'));

        // Act
        await categoriesProvider.load();
        expect(categoriesProvider.categories, isEmpty);

        // Setup second response
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, equals(categoriesData));
        verify(() => mockCategoriesApi.getCategories()).called(2);
      });

      test('should handle cache with large category lists', () async {
        // Arrange
        final categoriesData = List.generate(
          50,
          (index) => {
            'code': 'cat_$index',
            'display_name': 'Category $index',
            'envelope': {
              'name': 'Envelope $index',
              'monthly_amount': (index * 100).toDouble(),
              'account_code': 'BANK_$index',
            },
          },
        );

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories.length, equals(50));
        verify(() => mockCategoriesApi.getCategories()).called(1);
      });
    });

    group('state management', () {
      test('should maintain categories across multiple operations', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Food',
            'envelope': {
              'name': 'Food Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        final loadedCategories = categoriesProvider.categories;

        // Assert
        expect(loadedCategories, equals(categoriesData));
      });

      test('should clear error on successful retry after failure', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'test',
            'display_name': 'Test',
            'envelope': {
              'name': 'Test Envelope',
              'monthly_amount': 1000.0,
              'account_code': 'AXIS',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Network error'));

        // Act
        await categoriesProvider.load();
        expect(categoriesProvider.errorMessage, isNotNull);

        // Setup second response
        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNull);
        expect(categoriesProvider.categories, equals(categoriesData));
      });

      test('should preserve envelope info in cached categories', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Test Category',
            'envelope': {
              'name': 'Test Envelope',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        final envelope = categoriesProvider.categories[0]['envelope'];

        // Assert
        expect(envelope['name'], equals('Test Envelope'));
        expect(envelope['monthly_amount'], equals(5000.0));
        expect(envelope['account_code'], equals('ICICI'));
      });

      test('should handle error message updates correctly', () async {
        // Arrange
        when(() => mockCategoriesApi.getCategories())
            .thenThrow(Exception('Failed to load'));

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.errorMessage, isNotNull);
      });
    });

    group('concurrent operations', () {
      test('should deduplicate concurrent load calls to same in-flight future',
          () async {
        // Arrange
        var apiCallCount = 0;
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Food',
            'envelope': {
              'name': 'Food Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories()).thenAnswer((_) async {
          apiCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return categoriesData;
        });

        // Act
        final future1 = categoriesProvider.load();
        final future2 = categoriesProvider.load();
        await Future.wait([future1, future2]);

        // Assert - should only call API once due to in-flight dedup
        expect(apiCallCount, equals(1));
        expect(categoriesProvider.categories, equals(categoriesData));
      });

      test('should handle load and forceRefresh separately without dedup',
          () async {
        // Arrange
        var apiCallCount = 0;
        final categoriesData = [
          {
            'code': 'test',
            'display_name': 'Test',
            'envelope': {
              'name': 'Test Envelope',
              'monthly_amount': 1000.0,
              'account_code': 'AXIS',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories()).thenAnswer((_) async {
          apiCallCount++;
          return categoriesData;
        });

        // Act
        final future1 = categoriesProvider.load();
        final future2 = categoriesProvider.load(forceRefresh: true);
        await Future.wait([future1, future2]);

        // Assert
        expect(apiCallCount, equals(2));
      });
    });

    group('provider integration', () {
      test('should expose categories getter for other features', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'food',
            'display_name': 'Food',
            'envelope': {
              'name': 'Food Budget',
              'monthly_amount': 5000.0,
              'account_code': 'ICICI',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();

        // Assert
        expect(categoriesProvider.categories, equals(categoriesData));
      });

      test('should expose load method for manual refresh', () async {
        // Arrange
        final categoriesData = [
          {
            'code': 'test',
            'display_name': 'Test',
            'envelope': {
              'name': 'Test Envelope',
              'monthly_amount': 1000.0,
              'account_code': 'AXIS',
            },
          },
        ];

        when(() => mockCategoriesApi.getCategories())
            .thenAnswer((_) async => categoriesData);

        // Act
        await categoriesProvider.load();
        await categoriesProvider.load(forceRefresh: true);

        // Assert
        expect(categoriesProvider.categories, equals(categoriesData));
        verify(() => mockCategoriesApi.getCategories()).called(2);
      });

      test('should extend ChangeNotifier for provider pattern', () {
        // Act & Assert
        expect(categoriesProvider, isA<ChangeNotifier>());
      });
    });
  });
}
