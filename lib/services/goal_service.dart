import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class GoalService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  GoalService(this._apiClient);

  /// Đăng ký/cập nhật mục tiêu của người dùng
  Future<Response?> saveGoal(Map<String, dynamic> goalData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/goals',
        data: goalData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi lưu mục tiêu trên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy mục tiêu đang hoạt động của người dùng
  Future<Response?> getActiveGoal(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/goals/user/$userId/active',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải mục tiêu hoạt động từ server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy đề xuất bài tập và dinh dưỡng dựa trên mục tiêu hoạt động
  Future<Response?> getRecommendations(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/goals/user/$userId/recommendations',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải đề xuất từ server: ${e.message}");
      return e.response;
    }
  }
}
