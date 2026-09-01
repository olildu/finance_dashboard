import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/rollover/business/rollover_provider.dart';
import 'package:finance_dashboard/features/rollover/data/rollover_api.dart';

class MockRolloverApi extends Mock implements RolloverApi {}

void main() {
  group('RolloverProvider', () {
    late MockRolloverApi mockRolloverApi;

    setUp(() {
      mockRolloverApi = MockRolloverApi();
    });

    group('initialization', () {
      test('should initialize with isLoading as false', () {
        // Act
        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Assert
        expect(provider.isLoading, false);
      });

      test('should initialize with errorMessage as null', () {
        // Act
        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should initialize with lastResult as null', () {
        // Act
        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Assert
        expect(provider.lastResult, isNull);
      });

      test('should start with no pending trigger', () {
        // Act
        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.lastResult, isNull);
      });
    });

    group('trigger', () {
      test('should call triggerCheck API method', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        await provider.trigger();

        // Assert
        verify(() => mockRolloverApi.triggerCheck()).called(1);
      });

      test('should set isLoading to true during trigger', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act & Assert - check that isLoading changes
        final triggerFuture = provider.trigger();
        expect(provider.isLoading, true);

        await triggerFuture;
        expect(provider.isLoading, false);
      });

      test('should set isLoading to false after successful trigger', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        await provider.trigger();

        // Assert
        expect(provider.isLoading, false);
      });

      test('should store result in lastResult on successful trigger', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        await provider.trigger();

        // Assert
        expect(provider.lastResult, isNotNull);
        expect(provider.lastResult, equals(response));
      });

      test('should populate lastResult with status and message', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': '2 months processed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        await provider.trigger();

        // Assert
        expect(provider.lastResult!['status'], equals('success'));
        expect(provider.lastResult!['message'], equals('2 months processed'));
      });

      test('should clear errorMessage on successful trigger', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        await provider.trigger();

        // Assert
        expect(provider.errorMessage, isNull);
      });

      test('should set errorMessage on trigger failure', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('API Error: Network timeout'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('API Error'));
      });

      test('should set isLoading to false on trigger error', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Network error'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert
        expect(provider.isLoading, false);
      });

      test('should maintain previous lastResult on trigger failure', () async {
        // Arrange
        final successResponse = {
          'status': 'success',
          'message': 'Previous success',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => successResponse,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);
        await provider.trigger();

        // Setup second trigger to fail
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Second trigger failed'),
        );

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert - lastResult should still contain previous success
        expect(provider.lastResult, equals(successResponse));
      });

      test('should handle server errors gracefully', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Server Error: 500 Internal Server Error'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert
        expect(provider.errorMessage, isNotNull);
        expect(provider.isLoading, false);
      });

      test('should rethrow exception from API', () async {
        // Arrange
        final exception = Exception('Trigger failed');

        when(() => mockRolloverApi.triggerCheck()).thenThrow(exception);

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act & Assert
        expect(
          () => provider.trigger(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle multiple concurrent triggers', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act - call trigger multiple times concurrently
        await Future.wait([
          provider.trigger(),
          provider.trigger(),
          provider.trigger(),
        ]);

        // Assert - API should be called only once (request coalescing)
        verify(() => mockRolloverApi.triggerCheck()).called(1);
        expect(provider.lastResult, equals(response));
      });

      test('should handle concurrent triggers when first one fails', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Trigger failed'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act - call trigger multiple times concurrently (all should fail together)
        var failureCount = 0;
        await Future.wait([
          provider.trigger().onError((_, __) {
            failureCount++;
            return null;
          }),
          provider.trigger().onError((_, __) {
            failureCount++;
            return null;
          }),
        ]);

        // Assert - API should be called only once, both concurrent calls fail
        verify(() => mockRolloverApi.triggerCheck()).called(1);
        expect(provider.errorMessage, isNotNull);
      });

      test('should allow new trigger after previous one completes', () async {
        // Arrange
        final response1 = {
          'status': 'success',
          'message': 'First trigger',
        };
        final response2 = {
          'status': 'success',
          'message': 'Second trigger',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response1,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act - first trigger
        await provider.trigger();
        expect(provider.lastResult!['message'], equals('First trigger'));

        // Setup second response
        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response2,
        );

        // Act - second trigger
        await provider.trigger();

        // Assert
        expect(provider.lastResult!['message'], equals('Second trigger'));
        verify(() => mockRolloverApi.triggerCheck()).called(2);
      });
    });

    group('state transitions', () {
      test('should transition from loading to loaded state', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        final triggerFuture = provider.trigger();

        // Assert - isLoading should be true
        expect(provider.isLoading, true);

        await triggerFuture;

        // Assert - isLoading should be false
        expect(provider.isLoading, false);
        expect(provider.lastResult, isNotNull);
      });

      test('should transition to error state on failure', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Trigger failed'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert
        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNotNull);
      });

      test('should transition from error to success on retry', () async {
        // Arrange - first trigger fails
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('First attempt failed'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);

        // Act - first trigger
        try {
          await provider.trigger();
        } catch (_) {}

        expect(provider.errorMessage, isNotNull);

        // Setup successful response
        final successResponse = {
          'status': 'success',
          'message': 'Retry succeeded',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => successResponse,
        );

        // Act - retry trigger
        await provider.trigger();

        // Assert
        expect(provider.errorMessage, isNull);
        expect(provider.lastResult, isNotNull);
        expect(provider.lastResult!['message'], equals('Retry succeeded'));
      });
    });

    group('notification behavior', () {
      test('should notify listeners when trigger starts', () async {
        // Arrange
        final response = {
          'status': 'success',
          'message': 'Rollover check completed',
        };

        when(() => mockRolloverApi.triggerCheck()).thenAnswer(
          (_) async => response,
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);
        var notificationCount = 0;

        provider.addListener(() {
          notificationCount++;
        });

        // Act
        await provider.trigger();

        // Assert - should be called at least twice (start and end of trigger)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('should notify listeners on error', () async {
        // Arrange
        when(() => mockRolloverApi.triggerCheck()).thenThrow(
          Exception('Trigger failed'),
        );

        final provider = RolloverProvider(rolloverApi: mockRolloverApi);
        var notificationCount = 0;

        provider.addListener(() {
          notificationCount++;
        });

        // Act
        try {
          await provider.trigger();
        } catch (_) {}

        // Assert - should be called at least twice (start and end of trigger)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
