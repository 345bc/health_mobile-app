import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';

class ReminderService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  ReminderService(this._apiClient);

  Future<Response?> saveReminder(Map<String, dynamic> reminderData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.post(
        '/reminders',
        data: reminderData,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi gửi reminder lên server: ${e.message}");
      return e.response;
    }
  }

  Future<Response?> getRemindersByUser(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/reminders/user/$userId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi khi tải reminders của user từ server: ${e.message}");
      return e.response;
    }
  }
}
