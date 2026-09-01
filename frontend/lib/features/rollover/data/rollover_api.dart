import 'package:dio/dio.dart';

/// RolloverApi handles all rollover-related API calls
/// The rollover process is primarily backend-driven by a cron scheduler,
/// but this API provides a manual trigger endpoint for debugging/testing
class RolloverApi {
  final Dio dio;

  RolloverApi(this.dio);

  /// Trigger a manual rollover check on the server
  /// This is useful for testing and manual intervention
  /// Returns the raw RolloverRunResult map: months_closed (List<int>),
  /// credit_settled_amounts (List<num>), sweep_amounts (List<num>)
  /// Throws an exception on failure
  Future<Map<String, dynamic>> triggerCheck() async {
    try {
      final response = await dio.post('/rollover/run-check');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
