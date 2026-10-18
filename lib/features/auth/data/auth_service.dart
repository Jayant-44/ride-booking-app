import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/config/api_client.dart';
import 'user_model.dart';
import 'dart:async';

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
  
  // THE FIX: Added AndroidOptions to prevent random null returns on Android
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ============================================================
  // LOGIN
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
          'uniqueId': ?uniqueId,
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
  // CUSTOMER REGISTER
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
  // DRIVER REGISTER
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
      final message =
          e.response?.data?['message']?.toString() ?? 'Unable to register';
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // ADMIN REGISTER
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
      final message =
          e.response?.data?['message']?.toString() ?? 'Unable to register';
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================
  Future<AuthResult> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/me',
        data: {
          'fullName': ?fullName,
          'phone': ?phone,
        },
      );

      final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
      await _storage.write(key: 'user_json', value: jsonEncode(user.toJson()));
      return AuthResult.success(user: user, token: '');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Update failed';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  Future<RegistrationResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final message = response.data['message']?.toString() ?? 'Password updated';
      return RegistrationResult.success(message);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Failed to change password';
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Unexpected error: $e');
    }
  }

  // ============================================================
  // SETTINGS
  // ============================================================
  Future<AuthResult> updateSettings({
    String? timezone,
    String? currency,
    String? locale,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/settings',
        data: {
          'timezone': ?timezone,
          'currency': ?currency,
          'locale': ?locale,
        },
      );

      final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
      await _storage.write(key: 'user_json', value: jsonEncode(user.toJson()));
      return AuthResult.success(user: user, token: '');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Update failed';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
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

    // Best-effort: register FCM token
    unawaited(registerFcmToken());

    return AuthResult.success(user: user, token: token);
  }

  Future<User?> getStoredUser() async {
    try {
      final jsonStr = await _storage.read(key: 'user_json');
      if (jsonStr == null) return null;
      return User.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await unregisterFcmToken();
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_json');
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      return token != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> registerFcmToken() async {
    try {
      final token = await NotificationService().getToken();
      if (token == null) return;
      await _dio.post(
        '/notifications/register-token',
        data: {'token': token},
      );
    } catch (_) {}
  }

  Future<void> unregisterFcmToken() async {
    try {
      await _dio.post('/notifications/unregister-token');
    } catch (_) {}
  }
}