import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/budgets/data/budgets_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockBudgetsApi extends Mock implements BudgetsApi {}

void main() {
  group('BudgetsProvider', () {
    late MockBudgetsApi mockBudgetsApi;
    late BudgetsProvider budgetsProvider;

    setUp(() {
      mockBudgetsApi = MockBudgetsApi();
      budgetsProvider = BudgetsProvider(budgetsApi: mockBudgetsApi);
    });

    group('initialization', () {
      test('should initialize with empty categories list', () {
        // Arrange & Act & Assert
        expect(budgetsProvider.categories, isEmpty);
      });

      test('should initialize isLoading as false', () {
        // Arrange & Act & Assert
        expect(budgetsProvider.isLoading, isFalse);
      });

      test('should initialize errorMessage as null', () {
        // Arrange & Act & Assert
        expect(budgetsProvider.errorMessage, isNull);
      });

      test('should not call API on initialization', () {
        // Arrange & Act & Assert
        verifyNever(() => mockBudgetsApi.getStatus());
      });
    });

    group('load', () {
      test('should successfully load categories', () async {
        // Arrange
        final statusData = {
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
          ],
        };

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories.length, equals(2));
        expect(budgetsProvider.categories[0]['category_code'], equals('food'));
        expect(budgetsProvider.categories[1]['category_code'], equals('transport'));
        expect(budgetsProvider.isLoading, isFalse);
        expect(budgetsProvider.errorMessage, isNull);
        verify(() => mockBudgetsApi.getStatus()).called(1);
      });

      test('should set isLoading to true during load', () async {
        // Arrange
        when(() => mockBudgetsApi.getStatus()).thenAnswer((_) async {
          expect(budgetsProvider.isLoading, isTrue);
          return {
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
        });

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.isLoading, isFalse);
      });

      test('should clear error message on successful load', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNull);
      });

      test('should set errorMessage and keep isLoading false on API failure',
          () async {
        // Arrange
        const errorMessage = 'Failed to load budget status';

        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception(errorMessage));

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNotNull);
        expect(budgetsProvider.isLoading, isFalse);
        expect(budgetsProvider.categories, isEmpty);
      });

      test('should populate categories list on successful load', () async {
        // Arrange
        final statusData = {
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
          ],
        };

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories.length, equals(2));
        expect(budgetsProvider.categories[0]['category_code'], equals('food'));
        expect(budgetsProvider.categories[1]['category_code'], equals('transport'));
      });

      test('should handle empty categories list', () async {
        // Arrange
        final statusData = {'categories': []};

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories, isEmpty);
        expect(budgetsProvider.errorMessage, isNull);
      });

      test('should set isLoading to false on load completion', () async {
        // Arrange
        final statusData = {'categories': []};

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.isLoading, isFalse);
      });

      test('should handle network timeout errors gracefully', () async {
        // Arrange
        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Network timeout'));

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNotNull);
        expect(budgetsProvider.errorMessage, contains('timeout'));
      });

      test('should handle 401 unauthorized errors', () async {
        // Arrange
        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Unauthorized (HTTP 401)'));

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNotNull);
      });

      test('should handle server (500) errors gracefully', () async {
        // Arrange
        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Server error (HTTP 500)'));

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNotNull);
      });
    });

    group('caching behavior', () {
      test('should cache categories and not call API twice on consecutive loads',
          () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();
        final firstLoadCategories = budgetsProvider.categories;
        await budgetsProvider.load();
        final secondLoadCategories = budgetsProvider.categories;

        // Assert
        expect(firstLoadCategories, equals(secondLoadCategories));
        verify(() => mockBudgetsApi.getStatus()).called(1);
      });

      test('should bypass cache when forceRefresh is true', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();
        await budgetsProvider.load(forceRefresh: true);

        // Assert
        verify(() => mockBudgetsApi.getStatus()).called(2);
      });

      test('should refetch data when forceRefresh is true', () async {
        // Arrange
        final initialData = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Old Name',
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

        final updatedData = {
          'categories': [
            {
              'category_code': 'food',
              'display_name': 'Updated Name',
              'budget': 6000.0,
              'spent': 1500.0,
              'remaining': 4500.0,
              'days_left': 25,
              'allowance_per_day': 180.0,
              'burn_rate_per_day': 150.0,
              'projected_runout_date': null,
            },
          ],
        };

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => initialData);

        // Act
        await budgetsProvider.load();
        expect(budgetsProvider.categories[0]['display_name'], equals('Old Name'));

        // Setup second response
        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => updatedData);

        await budgetsProvider.load(forceRefresh: true);

        // Assert
        expect(budgetsProvider.categories[0]['display_name'],
            equals('Updated Name'));
        expect(budgetsProvider.categories[0]['budget'], equals(6000.0));
      });

      test('should not cache data when load fails', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Network error'));

        // Act
        await budgetsProvider.load();
        expect(budgetsProvider.categories, isEmpty);

        // Setup second response
        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories, equals(statusData['categories']));
        verify(() => mockBudgetsApi.getStatus()).called(2);
      });

      test('should handle cache with large category lists', () async {
        // Arrange
        final categories = List.generate(
          10,
          (index) => {
            'category_code': 'cat_$index',
            'display_name': 'Category $index',
            'budget': (1000.0 + index * 100),
            'spent': (index * 50).toDouble(),
            'remaining': (1000.0 + index * 50),
            'days_left': 25,
            'allowance_per_day': (40.0 + index * 2),
            'burn_rate_per_day': (index * 2).toDouble(),
            'projected_runout_date': null,
          },
        );

        final statusData = {'categories': categories};

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories.length, equals(10));
        verify(() => mockBudgetsApi.getStatus()).called(1);
      });
    });

    group('state management', () {
      test('should maintain categories across multiple operations', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();
        final loadedCategories = budgetsProvider.categories;

        // Assert
        expect(loadedCategories, equals(statusData['categories']));
      });

      test('should clear error on successful retry after failure', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Network error'));

        // Act
        await budgetsProvider.load();
        expect(budgetsProvider.errorMessage, isNotNull);

        // Setup second response
        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNull);
        expect(budgetsProvider.categories, equals(statusData['categories']));
      });

      test('should handle error message updates correctly', () async {
        // Arrange
        when(() => mockBudgetsApi.getStatus())
            .thenThrow(Exception('Failed to load'));

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNotNull);
      });

      test('should preserve all category fields in state', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();
        final category = budgetsProvider.categories[0];

        // Assert
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
    });

    group('concurrent operations', () {
      test('should deduplicate concurrent load calls to same in-flight future',
          () async {
        // Arrange
        var apiCallCount = 0;
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus()).thenAnswer((_) async {
          apiCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return statusData;
        });

        // Act
        final future1 = budgetsProvider.load();
        final future2 = budgetsProvider.load();
        await Future.wait([future1, future2]);

        // Assert - should only call API once due to in-flight dedup
        expect(apiCallCount, equals(1));
        expect(budgetsProvider.categories, equals(statusData['categories']));
      });

      test('should handle load and forceRefresh separately without dedup',
          () async {
        // Arrange
        var apiCallCount = 0;
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus()).thenAnswer((_) async {
          apiCallCount++;
          return statusData;
        });

        // Act
        final future1 = budgetsProvider.load();
        final future2 = budgetsProvider.load(forceRefresh: true);
        await Future.wait([future1, future2]);

        // Assert
        expect(apiCallCount, equals(2));
      });

      test(
          'should clear in-flight future on exception for retry on next load',
          () async {
        // Arrange
        var apiCallCount = 0;
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus()).thenAnswer((_) async {
          apiCallCount++;
          if (apiCallCount == 1) {
            throw Exception('First load fails');
          }
          return statusData;
        });

        // Act
        await budgetsProvider.load();
        expect(budgetsProvider.errorMessage, isNotNull);

        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.errorMessage, isNull);
        expect(budgetsProvider.categories, equals(statusData['categories']));
        expect(apiCallCount, equals(2));
      });
    });

    group('provider integration', () {
      test('should expose categories getter for other features', () async {
        // Arrange
        final statusData = {
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

        when(() => mockBudgetsApi.getStatus())
            .thenAnswer((_) async => statusData);

        // Act
        await budgetsProvider.load();

        // Assert
        expect(budgetsProvider.categories, equals(statusData['categories']));
      });

      test('should extend ChangeNotifier for provider pattern', () {
        // Act & Assert
        expect(budgetsProvider, isA<ChangeNotifier>());
      });
    });
  });
}
