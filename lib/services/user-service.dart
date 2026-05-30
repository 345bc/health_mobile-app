import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:frontend/services/token_service.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  UserService(this._apiClient);

  Future<Response> signin(String email, String password) async {
    final response = await _apiClient.dio.post(
      '/auth/sign-in',
      data: {'email': email, 'password': password},
    );

    print('Data: ${response.data['data']}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data as Map<String, dynamic>;

      final dynamic innerData = responseData['data'];
      if (innerData is Map<String, dynamic>) {
        await _tokenService.saveToken(innerData['token'] ?? '');
        await _tokenService.saveUser(innerData['user'] ?? {});
      }
    }

    return response;
  }

  Future<Response> signup(String email, String password, String name) async {
    final response = await _apiClient.dio.post(
      '/users',
      data: {'email': email, 'password': password, 'name': name},
    );
    return response;
  }

  Future<void> logout() async {
    await _tokenService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.isSignIn();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _tokenService.getUser();
  }

  Future<Response?> getEndUserProfile(int userId) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.get(
        '/end-users/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Không thể lấy end-user profile: ${e.message}");
      return null;
    }
  }

  Future<Response?> updateEndUserProfile(Map<String, dynamic> endUserData) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.put(
        '/end-users',
        data: endUserData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Không thể cập nhật end-user profile: ${e.message}");
      return null;
    }
  }
}
