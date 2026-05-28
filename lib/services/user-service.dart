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

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data is String
          ? jsonDecode(response.data)
          : response.data as Map<String, dynamic>;

      await _tokenService.saveToken(data['token'] ?? '');
      await _tokenService.saveUser(data['user'] ?? {});
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

  // Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  //   try {
  //     final response = await _apiClient.dio.get('/users/$userId');

  //     return response.data as Map<String, dynamic>;
  //   } on DioException catch (e) {
  //     print("Không thể lấy profile: ${e.message}");
  //     return null;
  //   }
  // }
}
