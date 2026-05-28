// import 'dart:ffi';

import 'package:dio/dio.dart';

class ApiService {
  // static const String baseUrl = "http://127.0.0.1:8080/api/v1";
  static const String baseUrl = "http://192.168.2.22:8080/api/v1";
  // static const String baseUrl = "http://10.0.2.2:8080/api/v1";
  final Dio _dio = Dio();

  ApiService() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print("🚀 Gửi Request: [${options.method}] -> ${options.uri}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            "✅ Nhận Response: [${response.statusCode}] <- ${response.requestOptions.path}",
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print("❌ Lỗi API: [${e.response?.statusCode}] -> ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }
  Dio get dio => _dio;
}
