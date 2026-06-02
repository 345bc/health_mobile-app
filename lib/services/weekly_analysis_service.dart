import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class WeeklyAnalysisService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  WeeklyAnalysisService(this._apiClient);

  /// Lấy thống kê so sánh tuần này so với tuần trước kèm lời khuyên
  Future<Response?> getWeeklyAnalysis(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/users/$userId/weekly-analysis',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải thống kê phân tích tuần từ server: ${e.message}");
      return e.response;
    }
  }
}
