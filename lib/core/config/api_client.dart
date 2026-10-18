import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

      dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException error, ErrorInterceptorHandler handler) async {
      // ONLY log out if the backend explicitly says Unauthorized (401).
      // Do NOT log out on 502/503 (Render sleeping) or network timeouts.
      if (error.response?.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        await _storage.delete(key: 'user_json');
        // Let the router handle the redirect naturally
      }
      handler.next(error);
    },
  ));
  }
}