import 'package:dio/dio.dart';
import 'package:frontend/services/token_service.dart';

class ApiService {
  // static const String baseUrl = "http://127.0.0.1:8080/api/v1";
  static const String baseUrl = "http://10.186.78.61:8080/api/v1";

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await tokenService().getToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
          ),
        );

  static Dio get dio => _dio;

  // 1. Auth & Account
  static Future<Map<String, dynamic>> signin(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/sign-in',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        final innerData = data['data'];
        await tokenService().saveToken(innerData['token'] ?? '');
        await tokenService().saveUser(innerData['user'] ?? {});
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> signup(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {'email': email, 'password': password, 'name': name},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> getEndUserProfile(int userId) async {
    try {
      final response = await _dio.get('/end-users/user/$userId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> updateEndUserProfile(
    int userId,
    Map<String, dynamic> endUserData,
  ) async {
    try {
      final response = await _dio.patch(
        '/end-users/user/$userId',
        data: endUserData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> updateUserAccount(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _dio.patch('/users/$userId', data: userData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 2. Water Logs
  static Future<Map<String, dynamic>> createWaterLog(
    Map<String, dynamic> waterData,
  ) async {
    try {
      final response = await _dio.post('/water-logs', data: waterData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getWaterLogsByUser(int userId) async {
    try {
      final response = await _dio.get('/water-logs/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> getTodayTotalWater(int userId) async {
    try {
      final response = await _dio.get('/water-logs/user/$userId/today');
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteWaterLog(int logId) async {
    try {
      await _dio.delete('/water-logs/$logId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 3. Sleep Logs
  static Future<Map<String, dynamic>> createSleep(
    Map<String, dynamic> sleepData,
  ) async {
    try {
      final response = await _dio.post('/sleeps', data: sleepData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> updateSleep(
    int id,
    Map<String, dynamic> sleepData,
  ) async {
    try {
      final response = await _dio.put('/sleeps/$id', data: sleepData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getSleepsByUser(int userId) async {
    try {
      final response = await _dio.get('/sleeps/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteSleep(int id) async {
    try {
      await _dio.delete('/sleeps/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 4. Activity Logs
  static Future<Map<String, dynamic>> createActivity(
    Map<String, dynamic> activityData,
  ) async {
    try {
      final response = await _dio.post('/activities', data: activityData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> updateActivity(
    int id,
    Map<String, dynamic> activityData,
  ) async {
    try {
      final response = await _dio.put('/activities/$id', data: activityData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getActivitiesByUser(int userId) async {
    try {
      final response = await _dio.get('/activities/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteActivity(int id) async {
    try {
      await _dio.delete('/activities/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 5. Nutrition Logs & Foods
  static Future<Map<String, dynamic>> createFood(
    Map<String, dynamic> foodData,
  ) async {
    try {
      final response = await _dio.post('/foods', data: foodData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> searchFoods(String name) async {
    try {
      final response = await _dio.get(
        '/foods/search',
        queryParameters: {'name': name},
      );
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> createNutritionLog(
    Map<String, dynamic> logData,
  ) async {
    try {
      final response = await _dio.post('/nutrition-logs', data: logData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getAllNutritionLogsByUser(int userId) async {
    try {
      final response = await _dio.get('/nutrition-logs/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getNutritionLogs(int userId, String date) async {
    try {
      final response = await _dio.get(
        '/nutrition-logs/user/$userId',
        queryParameters: {'date': date},
      );
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteNutritionLog(int logId) async {
    try {
      await _dio.delete('/nutrition-logs/$logId');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 6. Body Measurements
  static Future<Map<String, dynamic>> createBodyMeasurement(
    Map<String, dynamic> measurementData,
  ) async {
    try {
      final response = await _dio.post(
        '/body-measurements',
        data: measurementData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getBodyMeasurementsByUser(int userId) async {
    try {
      final response = await _dio.get('/body-measurements/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> updateBodyMeasurement(
    int id,
    Map<String, dynamic> measurementData,
  ) async {
    try {
      final response = await _dio.put(
        '/body-measurements/$id',
        data: measurementData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteBodyMeasurement(int id) async {
    try {
      await _dio.delete('/body-measurements/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 7. Mood Entries
  static Future<Map<String, dynamic>> createMoodEntry(
    Map<String, dynamic> moodData,
  ) async {
    try {
      final response = await _dio.post('/mood-entries', data: moodData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getMoodEntriesByUser(int userId) async {
    try {
      final response = await _dio.get('/mood-entries/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> updateMoodEntry(
    int id,
    Map<String, dynamic> moodData,
  ) async {
    try {
      final response = await _dio.put('/mood-entries/$id', data: moodData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<void> deleteMoodEntry(int id) async {
    try {
      await _dio.delete('/mood-entries/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // 8. Weekly Analysis & Reminders
  static Future<Map<String, dynamic>> getWeeklyAnalysis(int userId) async {
    try {
      final response = await _dio.get('/users/$userId/weekly-analysis');
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<Map<String, dynamic>> saveReminder(
    Map<String, dynamic> reminderData,
  ) async {
    try {
      final response = await _dio.post('/reminders', data: reminderData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  static Future<List<dynamic>> getRemindersByUser(int userId) async {
    try {
      final response = await _dio.get('/reminders/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Error Mapper
  static String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "Máy chủ không phản hồi (quá 10 giây). Vui lòng thử lại sau!";
    } else if (e.type == DioExceptionType.connectionError) {
      return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng!";
    }

    if (e.response != null && e.response!.data != null) {
      final respData = e.response!.data;
      if (respData is Map<String, dynamic> && respData.containsKey('message')) {
        return respData['message'] ?? "Lỗi máy chủ (${e.response!.statusCode})";
      }
    }

    return "Đã xảy ra lỗi hệ thống: ${e.message}";
  }
}
