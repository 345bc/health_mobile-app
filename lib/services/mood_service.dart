import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class MoodService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  MoodService(this._apiClient);

  /// Ghi nhận tâm trạng mới lên server
  Future<Response?> createMoodEntry(Map<String, dynamic> moodData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/mood-entries',
        data: moodData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi tâm trạng lên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy toàn bộ danh sách tâm trạng của người dùng từ server
  Future<Response?> getMoodEntriesByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/mood-entries/user/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải tâm trạng của user từ server: ${e.message}");
      return e.response;
    }
  }

  /// Xóa nhật ký tâm trạng trên server
  Future<Response?> deleteMoodEntry(int id) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/mood-entries/$id',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa tâm trạng trên server: ${e.message}");
      return e.response;
    }
  }
}
