import 'package:dio/dio.dart';

import '../../../core/config/api_client.dart';

class AdminStats {
  final int totalRides;
  final int pendingRides;
  final int confirmedRides;
  final int completedRides;

  const AdminStats({
    required this.totalRides,
    required this.pendingRides,
    required this.confirmedRides,
    required this.completedRides,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalRides: json['total'] as int? ?? 0,
        pendingRides: json['pending'] as int? ?? 0,
        confirmedRides: json['confirmed'] as int? ?? 0,
        completedRides: json['completed'] as int? ?? 0,
      );
}

class PendingUser {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String role;
  final DateTime createdAt;
  final String? licenseNo;
  final DateTime? licenseExpiry;
  final List<PendingVehicle> vehicles;

  const PendingUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.licenseNo,
    this.licenseExpiry,
    required this.vehicles,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final vehiclesJson = driver?['vehicles'] as List<dynamic>? ?? [];
    return PendingUser(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      licenseNo: driver?['licenseNo'] as String?,
      licenseExpiry: driver?['licenseExpiry'] != null
          ? DateTime.parse(driver!['licenseExpiry'] as String).toLocal()
          : null,
      vehicles: vehiclesJson
          .map((v) => PendingVehicle.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PendingVehicle {
  final String make;
  final String model;
  final String plateNo;
  final String color;
  final int capacity;
  final int luggageCapacity;

  const PendingVehicle({
    required this.make,
    required this.model,
    required this.plateNo,
    required this.color,
    required this.capacity,
    required this.luggageCapacity,
  });

  String get displayName => '$make $model';

  factory PendingVehicle.fromJson(Map<String, dynamic> json) => PendingVehicle(
        make: json['make'] as String,
        model: json['model'] as String,
        plateNo: json['plateNo'] as String,
        color: json['color'] as String,
        capacity: json['capacity'] as int,
        luggageCapacity: json['luggageCapacity'] as int? ?? 0,
      );
}

class AdminActionResult<T> {
  final bool success;
  final T? data;
  final String? error;

  AdminActionResult.success(this.data)
      : success = true,
        error = null;

  AdminActionResult.failure(this.error)
      : success = false,
        data = null;
}

class AdminService {
  final Dio _dio = ApiClient().dio;

  // ============================================================
  // STATS
  // ============================================================
  Future<AdminActionResult<AdminStats>> getStats() async {
    try {
      final res = await _dio.get('/admin/stats');
      return AdminActionResult.success(
        AdminStats.fromJson(res.data['data'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to load stats',
      );
    } catch (e) {
      return AdminActionResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // RIDES
  // ============================================================
  Future<AdminActionResult<List<dynamic>>> getRides() async {
    try {
      final res = await _dio.get('/admin/rides');
      return AdminActionResult.success(res.data['data'] as List<dynamic>);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to load rides',
      );
    } catch (e) {
      return AdminActionResult.failure('Unexpected error: $e');
    }
  }

  Future<AdminActionResult<void>> approveRide(String rideId) async {
    try {
      await _dio.patch('/admin/rides/$rideId/approve');
      return AdminActionResult.success(null);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to approve ride',
      );
    }
  }

  Future<AdminActionResult<void>> rejectRide(String rideId) async {
    try {
      await _dio.patch(
        '/admin/rides/$rideId/reject',
        data: {'reason': 'Rejected by admin'},
      );
      return AdminActionResult.success(null);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to reject ride',
      );
    }
  }

  // ============================================================
  // INVOICES
  // ============================================================
  Future<AdminActionResult<void>> createInvoice(
    String rideId, {
    required int subtotalCents,
    required int taxCents,
    String currencyCode = 'INR',
  }) async {
    try {
      await _dio.post(
        '/admin/rides/$rideId/invoice',
        data: {
          'subtotalCents': subtotalCents,
          'taxCents': taxCents,
          'currencyCode': currencyCode,
        },
      );
      return AdminActionResult.success(null);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to create invoice',
      );
    }
  }

  // ============================================================
  // PENDING USERS
  // ============================================================
  Future<AdminActionResult<List<PendingUser>>> getPendingUsers() async {
    try {
      final res = await _dio.get('/admin/pending-users');
      final data = (res.data['data'] as List<dynamic>)
          .map((e) => PendingUser.fromJson(e as Map<String, dynamic>))
          .toList();
      return AdminActionResult.success(data);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ??
            'Failed to load pending users',
      );
    }
  }

  Future<AdminActionResult<Map<String, dynamic>>> approveUser(
    String userId,
  ) async {
    try {
      final res = await _dio.post('/admin/users/$userId/approve');
      return AdminActionResult.success(
        res.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to approve',
      );
    }
  }

  Future<AdminActionResult<void>> rejectUser(String userId) async {
    try {
      await _dio.post(
        '/admin/users/$userId/reject',
        data: {'reason': 'Rejected by admin'},
      );
      return AdminActionResult.success(null);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to reject',
      );
    }
  }

  Future<AdminActionResult<int>> broadcastRide(String rideId) async {
    try {
      final res = await _dio.post('/admin/rides/$rideId/broadcast');
      final count = res.data['data']?['broadcast'] as int? ?? 0;
      return AdminActionResult.success(count);
    } on DioException catch (e) {
      return AdminActionResult.failure(
        e.response?.data?['message']?.toString() ?? 'Failed to broadcast',
      );
    }
  }
}