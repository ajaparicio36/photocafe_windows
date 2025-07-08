import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioClient {
  static final DioClient _singleton = DioClient._internal();
  static late Dio _dio;

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    _dio = Dio();

    // Ensure API_URL exists before setting it
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl != null && apiUrl.isNotEmpty) {
      _dio.options.baseUrl = apiUrl;
    } else {
      print('Warning: API_URL not found in .env file');
      _dio.options.baseUrl = 'https://default-api-url.com'; // Fallback URL
    }

    // Add logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get instance => _dio;
}
