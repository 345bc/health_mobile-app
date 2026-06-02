import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class ActivityService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  ActivityService(this._apiClient);

  /// Ghi nhận vận động mới lên server
  Future<Response?> createActivity(Map<String, dynamic> activityData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/activities',
        data: activityData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi vận động lên server: ${e.message}");
      return e.response;
    }
  }

  /// Cập nhật vận động trên server
  Future<Response?> updateActivity(int id, Map<String, dynamic> activityData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.put(
        '/activities/$id',
        data: activityData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi cập nhật vận động trên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy toàn bộ lịch sử vận động của người dùng từ server
  Future<Response?> getActivitiesByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/activities/user/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải lịch sử vận động của user từ server: ${e.message}");
      return e.response;
    }
  }

  /// Xóa vận động trên server
  Future<Response?> deleteActivity(int id) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/activities/$id',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa vận động trên server: ${e.message}");
      return e.response;
    }
  }
}
