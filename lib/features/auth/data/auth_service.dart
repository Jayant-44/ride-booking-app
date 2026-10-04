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

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString()
          ?? 'Unable to connect to server';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'CUSTOMER',
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
          'role': role,
          'timezone': timezone,
          'currency': currency,
          'locale': locale,
        },
      );

      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString()
          ?? 'Unable to connect to server';
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

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
    await _storage.delete(key: 'user_json');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}