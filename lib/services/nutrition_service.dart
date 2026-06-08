import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class NutritionService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  NutritionService(this._apiClient);

  /// Thêm món ăn mới vào thư viện backend
  Future<Response?> createFood(Map<String, dynamic> foodData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/foods',
        data: foodData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi thêm món ăn trên server: ${e.message}");
      return e.response;
    }
  }

  /// Tìm kiếm món ăn trên thư viện backend theo tên
  Future<Response?> searchFoods(String name) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/foods/search',
        queryParameters: {'name': name},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tìm kiếm món ăn trên server: ${e.message}");
      return e.response;
    }
  }

  /// Ghi nhận nhật ký bữa ăn mới lên backend
  Future<Response?> createNutritionLog(Map<String, dynamic> logData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/nutrition-logs',
        data: logData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi ghi nhận nhật ký dinh dưỡng lên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy tất cả nhật ký bữa ăn của người dùng (không lọc theo ngày)
  Future<Response?> getAllNutritionLogsByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/nutrition-logs/user/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải toàn bộ nhật ký dinh dưỡng từ server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy danh sách nhật ký bữa ăn của người dùng theo ngày
  Future<Response?> getNutritionLogs(int userId, String date) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/nutrition-logs/user/$userId',
        queryParameters: {'date': date},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải nhật ký dinh dưỡng từ server: ${e.message}");
      return e.response;
    }
  }

  /// Xóa nhật ký bữa ăn trên backend
  Future<Response?> deleteNutritionLog(int logId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/nutrition-logs/$logId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa nhật ký dinh dưỡng trên server: ${e.message}");
      return e.response;
    }
  }
}
