import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_dashboard/features/rollover/data/rollover_api.dart';

// Mock classes for testing
class MockDio extends Mock implements Dio {}

void main() {
  group('RolloverApi', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('triggerCheck', () {
      test('should call POST /rollover/run-check endpoint', () async {
        // Arrange
        final responseData = {'status': 'success', 'message': 'Rollover check completed'};

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        await rolloverApi.triggerCheck();

        // Assert
        verify(
          () => mockDio.post('/rollover/run-check'),
        ).called(1);
      });

      test('should return status from response', () async {
        // Arrange
        const expectedStatus = 'success';
        final responseData = {
          'status': expectedStatus,
          'message': 'Rollover check completed',
        };

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        final result = await rolloverApi.triggerCheck();

        // Assert
        expect(result['status'], equals(expectedStatus));
      });

      test('should return message from response', () async {
        // Arrange
        const expectedMessage = 'Rollover executed for 2 months';
        final responseData = {
          'status': 'success',
          'message': expectedMessage,
        };

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        final result = await rolloverApi.triggerCheck();

        // Assert
        expect(result['message'], equals(expectedMessage));
      });

      test('should parse both status and message fields correctly', () async {
        // Arrange
        final responseData = {
          'status': 'completed',
          'message': '3 months processed successfully',
        };

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        final result = await rolloverApi.triggerCheck();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['status'], isA<String>());
        expect(result['message'], isA<String>());
        expect(result['status'], equals('completed'));
        expect(result['message'], equals('3 months processed successfully'));
      });

      test('should handle empty message gracefully', () async {
        // Arrange
        final responseData = {
          'status': 'pending',
          'message': '',
        };

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        final result = await rolloverApi.triggerCheck();

        // Assert
        expect(result['status'], equals('pending'));
        expect(result['message'], equals(''));
      });

      test('should throw exception on API failure with 401 status', () async {
        // Arrange
        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/rollover/run-check'),
            response: Response(
              statusCode: 401,
              data: {'detail': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/rollover/run-check'),
            ),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act & Assert
        expect(
          () => rolloverApi.triggerCheck(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on API failure with 403 status', () async {
        // Arrange
        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/rollover/run-check'),
            response: Response(
              statusCode: 403,
              data: {'detail': 'Forbidden'},
              requestOptions: RequestOptions(path: '/rollover/run-check'),
            ),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act & Assert
        expect(
          () => rolloverApi.triggerCheck(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
            message: 'Connection timeout',
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act & Assert
        expect(
          () => rolloverApi.triggerCheck(),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw exception on server error (500)', () async {
        // Arrange
        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/rollover/run-check'),
            response: Response(
              statusCode: 500,
              data: {'detail': 'Internal server error'},
              requestOptions: RequestOptions(path: '/rollover/run-check'),
            ),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act & Assert
        expect(
          () => rolloverApi.triggerCheck(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle success response with additional fields', () async {
        // Arrange
        final responseData = {
          'status': 'success',
          'message': 'Rollover check completed',
          'months_processed': 2,
          'timestamp': '2024-09-01T12:00:00Z',
        };

        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act
        final result = await rolloverApi.triggerCheck();

        // Assert
        expect(result['status'], equals('success'));
        expect(result['message'], contains('completed'));
        expect(result.containsKey('months_processed'), true);
        expect(result['months_processed'], equals(2));
      });

      test('should throw exception on connection refused', () async {
        // Arrange
        when(
          () => mockDio.post('/rollover/run-check'),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(path: '/rollover/run-check'),
            message: 'Connection refused',
          ),
        );

        final rolloverApi = RolloverApi(mockDio);

        // Act & Assert
        expect(
          () => rolloverApi.triggerCheck(),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
