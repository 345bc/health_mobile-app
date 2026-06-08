import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class SleepService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  SleepService(this._apiClient);

  /// Ghi nhận giấc ngủ mới lên server
  Future<Response?> createSleep(Map<String, dynamic> sleepData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/sleeps',
        data: sleepData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi giấc ngủ lên server: ${e.message}");
      return e.response;
    }
  }

  /// Cập nhật giấc ngủ trên server
  Future<Response?> updateSleep(int id, Map<String, dynamic> sleepData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.put(
        '/sleeps/$id',
        data: sleepData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi cập nhật giấc ngủ trên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy toàn bộ lịch sử giấc ngủ của người dùng từ server
  Future<Response?> getSleepsByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/sleeps/user/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải lịch sử giấc ngủ của user từ server: ${e.message}");
      return e.response;
    }
  }

  /// Xóa giấc ngủ trên server
  Future<Response?> deleteSleep(int id) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/sleeps/$id',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa giấc ngủ trên server: ${e.message}");
      return e.response;
    }
  }
}
