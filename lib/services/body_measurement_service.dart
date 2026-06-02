import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class BodyMeasurementService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  BodyMeasurementService(this._apiClient);

  /// Ghi nhận sinh hiệu mới lên server (cân nặng, huyết áp, nhịp tim)
  Future<Response?> createBodyMeasurement(Map<String, dynamic> measurementData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/body-measurements',
        data: measurementData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi đo lường sinh hiệu lên server: ${e.message}");
      return e.response;
    }
  }

  /// Lấy toàn bộ đo lường sinh hiệu của người dùng từ server
  Future<Response?> getBodyMeasurementsByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/body-measurements/user/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải đo lường sinh hiệu của user từ server: ${e.message}");
      return e.response;
    }
  }

  /// Cập nhật đo lường sinh hiệu trên server
  Future<Response?> updateBodyMeasurement(int id, Map<String, dynamic> measurementData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.put(
        '/body-measurements/$id',
        data: measurementData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi cập nhật đo lường sinh hiệu trên server: ${e.message}");
      return e.response;
    }
  }

  /// Xóa đo lường sinh hiệu trên server
  Future<Response?> deleteBodyMeasurement(int id) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.delete(
        '/body-measurements/$id',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi xóa đo lường sinh hiệu trên server: ${e.message}");
      return e.response;
    }
  }
}
