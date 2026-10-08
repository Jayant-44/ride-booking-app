import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/api_client.dart';
import 'user_model.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  AuthResult.success({required this.user, required this.token})
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        user = null,
        token = null;
}

class RegistrationResult {
  final bool success;
  final String? message;
  final String? error;

  RegistrationResult.success(this.message)
      : success = true,
        error = null;

  RegistrationResult.failure(this.error)
      : success = false,
        message = null;
}

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ============================================================
  // LOGIN (all roles)
  // ============================================================
  Future<AuthResult> login({
    required String identifier,
    required String password,
    String? uniqueId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
          if (uniqueId != null && uniqueId.isNotEmpty) 'uniqueId': uniqueId,
        },
      );

      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to connect to server';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // CUSTOMER REGISTER (immediate access)
  // ============================================================
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String timezone = 'Asia/Kolkata',
    String currency = 'INR',
    String locale = 'en',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'timezone': timezone,
          'currency': currency,
          'locale': locale,
        },
      );

      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to connect to server';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // DRIVER REGISTER (pending approval)
  // ============================================================
  Future<RegistrationResult> registerDriver({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String licenseNo,
    required DateTime licenseExpiry,
    required String vehicleMake,
    required String vehicleModel,
    required String plateNo,
    required String vehicleColor,
    required int capacity,
    required int luggageCapacity,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register-driver',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'licenseNo': licenseNo,
          'licenseExpiry': licenseExpiry.toUtc().toIso8601String(),
          'timezone': 'Asia/Kolkata',
          'currency': 'INR',
          'locale': 'en',
          'vehicle': {
            'make': vehicleMake,
            'model': vehicleModel,
            'plateNo': plateNo,
            'color': vehicleColor,
            'capacity': capacity,
            'luggageCapacity': luggageCapacity,
          },
        },
      );

      final message = response.data['message']?.toString() ??
          'Registration received. Awaiting approval.';
      return RegistrationResult.success(message);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to register';
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // ADMIN REGISTER (pending super-admin approval)
  // ============================================================
  Future<RegistrationResult> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register-admin',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'timezone': 'Asia/Kolkata',
          'currency': 'INR',
          'locale': 'en',
        },
      );

      final message = response.data['message']?.toString() ??
          'Registration received. Awaiting super admin approval.';
      return RegistrationResult.success(message);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to register';
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Future<AuthResult> _handleAuthResponse(Response response) async {
    final data = response.data['data'];
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_json', value: jsonEncode(user.toJson()));

    return AuthResult.success(user: user, token: token);
  }

  Future<User?> getStoredUser() async {
    final jsonStr = await _storage.read(key: 'user_json');
    if (jsonStr == null) return null;
    return User.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_json');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}