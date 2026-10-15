import 'package:dio/dio.dart';

import '../../../core/config/api_client.dart';
import 'notification_model.dart';

class NotificationsResult {
  final bool success;
  final List<AppNotification>? items;
  final String? error;

  NotificationsResult.success(this.items)
      : success = true,
        error = null;

  NotificationsResult.failure(this.error)
      : success = false,
        items = null;
}

class UnreadCountResult {
  final bool success;
  final int count;

  UnreadCountResult.success(this.count) : success = true;
  UnreadCountResult.failure() : success = false, count = 0;
}

class NotificationsApi {
  final Dio _dio = ApiClient().dio;

  Future<NotificationsResult> list() async {
    try {
      final res = await _dio.get('/notifications');
      final data = (res.data['data'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationsResult.success(data);
    } on DioException catch (e) {
      return NotificationsResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to load',
      );
    } catch (e) {
      return NotificationsResult.failure('Unexpected error: $e');
    }
  }

  Future<UnreadCountResult> unreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      return UnreadCountResult.success(
        res.data['data']['count'] as int? ?? 0,
      );
    } catch (_) {
      return UnreadCountResult.failure();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (_) {}
  }
}