import 'package:dio/dio.dart';

import '../../../core/config/api_client.dart';
import 'ride_model.dart';

class RideResult {
  final bool success;
  final Ride? ride;
  final List<Ride>? rides;
  final String? error;

  RideResult.single({required this.ride})
      : success = true,
        rides = null,
        error = null;

  RideResult.list({required this.rides})
      : success = true,
        ride = null,
        error = null;

  RideResult.failure(this.error)
      : success = false,
        ride = null,
        rides = null;
}

class RideService {
  final Dio _dio = ApiClient().dio;

  Future<RideResult> createRide({
    required String pickupAddress,
    required String dropoffAddress,
    required DateTime scheduledAt,
    required int passengers,
    required int luggageCount,
    String? vehicleType,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/rides',
        data: {
  'pickupAddress': pickupAddress,
  'dropoffAddress': dropoffAddress,
  'scheduledAt': scheduledAt.toUtc().toIso8601String(),
  'passengers': passengers,
  'luggageCount': luggageCount,
  'vehicleType': ?vehicleType,
  if (notes case final n? when n.isNotEmpty) 'notes': n,
},
      );

      final ride = Ride.fromJson(response.data['data'] as Map<String, dynamic>);
      return RideResult.single(ride: ride);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString()
          ?? 'Unable to connect to server';
      return RideResult.failure(message);
    } catch (e) {
      return RideResult.failure('Unexpected error: $e');
    }
  }

  Future<RideResult> getMyRides() async {
    try {
      final response = await _dio.get('/rides/my');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final rides = data
          .map((r) => Ride.fromJson(r as Map<String, dynamic>))
          .toList();
      return RideResult.list(rides: rides);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString()
          ?? 'Unable to fetch rides';
      return RideResult.failure(message);
    } catch (e) {
      return RideResult.failure('Unexpected error: $e');
    }
  }

  Future<RideResult> cancelRide(String rideId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        '/rides/$rideId/cancel',
        data: {'reason': ?reason},
      );
      final ride = Ride.fromJson(response.data['data'] as Map<String, dynamic>);
      return RideResult.single(ride: ride);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString()
          ?? 'Unable to cancel ride';
      return RideResult.failure(message);
    } catch (e) {
      return RideResult.failure('Unexpected error: $e');
    }
  }
}