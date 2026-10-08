import 'package:dio/dio.dart';

import '../../../core/config/api_client.dart';
import 'driver_models.dart';

class AssignmentsResult {
  final bool success;
  final List<DriverAssignment>? assignments;
  final String? error;

  AssignmentsResult.success(this.assignments)
      : success = true,
        error = null;

  AssignmentsResult.failure(this.error)
      : success = false,
        assignments = null;
}

class AssignmentResult {
  final bool success;
  final DriverAssignment? assignment;
  final String? error;

  AssignmentResult.success(this.assignment)
      : success = true,
        error = null;

  AssignmentResult.failure(this.error)
      : success = false,
        assignment = null;
}

class ActionResult {
  final bool success;
  final String? error;

  ActionResult.success() : success = true, error = null;
  ActionResult.failure(this.error) : success = false;
}

class DriverService {
  final Dio _dio = ApiClient().dio;

  Future<AssignmentsResult> getMyAssignments() async {
    try {
      final response = await _dio.get('/driver/assignments');
      final data = response.data['data'] as List<dynamic>;
      final list = data
          .map((e) => DriverAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
      return AssignmentsResult.success(list);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Unable to load assignments';
      return AssignmentsResult.failure(msg);
    } catch (e) {
      return AssignmentsResult.failure('Unexpected error: $e');
    }
  }

  Future<AssignmentResult> getAssignmentDetail(String id) async {
    try {
      final response = await _dio.get('/driver/assignments/$id');
      final assignment =
          DriverAssignment.fromJson(response.data['data'] as Map<String, dynamic>);
      return AssignmentResult.success(assignment);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Unable to load assignment';
      return AssignmentResult.failure(msg);
    } catch (e) {
      return AssignmentResult.failure('Unexpected error: $e');
    }
  }

  Future<ActionResult> acceptAssignment(String id) async {
    try {
      await _dio.patch('/driver/assignments/$id/accept');
      return ActionResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Unable to accept';
      return ActionResult.failure(msg);
    } catch (e) {
      return ActionResult.failure('Unexpected error: $e');
    }
  }

  Future<ActionResult> rejectAssignment(String id, {String? reason}) async {
    try {
      await _dio.patch(
        '/driver/assignments/$id/reject',
        data: {'reason': reason ?? 'Declined by driver'},
      );
      return ActionResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Unable to reject';
      return ActionResult.failure(msg);
    } catch (e) {
      return ActionResult.failure('Unexpected error: $e');
    }
  }

  /// Progresses the trip status.
  /// [newStatus] must be one of: EN_ROUTE, ARRIVED, IN_PROGRESS, COMPLETED
  Future<ActionResult> progressRide(String rideId, String newStatus) async {
    try {
      await _dio.patch(
        '/driver/rides/$rideId/status',
        data: {'status': newStatus},
      );
      return ActionResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'Unable to update status';
      return ActionResult.failure(msg);
    } catch (e) {
      return ActionResult.failure('Unexpected error: $e');
    }
  }
}