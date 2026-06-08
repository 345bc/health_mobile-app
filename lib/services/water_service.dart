import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class WaterService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  WaterService(this._apiClient);

  Future<Response?> createWaterLog(Map<String, dynamic> waterData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/water-logs',
        data: waterData,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi nhật ký nước uống lên server: ${e.message}");
      return e.response;
    }
  }

  Future<Response?> getWaterLogsByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/water-logs/user/$userId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải lịch sử nước uống của user từ server: ${e.message}");
      return e.response;
    }
  }

  Future<Response?> deleteWaterLog(int id) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/water-logs/$id',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa nhật ký nước uống trên server: ${e.message}");
      return e.response;
    }
  }
}
