import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/token_service.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiClient;
  final tokenService _tokenService = tokenService();

  UserService(this._apiClient);

  Future<Response?> signin(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/sign-in',
        data: {'email': email, 'password': password},
      );

      if (response.data != null &&
          response.data is Map<String, dynamic> &&
          response.data['data'] != null) {
        print('Data: ${response.data['data']}');
      }

      if (response.statusCode == 200 && response.data != null) {
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
    } on DioException catch (e) {
      // ✅ LOG LỖI
      print("❌ Login error: ${e.message}");

      if (e.type == DioExceptionType.connectionError) {
        print("👉 Không kết nối được server");
      } else if (e.type == DioExceptionType.connectionTimeout) {
        print("👉 Server quá chậm");
      }

      rethrow; // ✅ RE-THROW để SigninScreen bắt được lỗi và kích hoạt chế độ ngoại tuyến
    } catch (e) {
      print("❌ Login error (lỗi hệ thống): $e");
      rethrow;
    }
  }

  Future<Response> signup(String email, String password, String name) async {
    try {
      final response = await _apiClient.dio.post(
        '/users',
        data: {'email': email, 'password': password, 'name': name},
      );
      return response;
    } on DioException catch (e) {
      print("Lỗi đăng ký: ${e.message}");
      rethrow;
    }
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
        '/end-users/user/$userId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Không thể lấy end-user profile: ${e.message}");
      rethrow;
    } catch (e) {
      print("Không thể lấy end-user profile (lỗi hệ thống): $e");
      rethrow;
    }
  }

  Future<Response?> updateEndUserProfile(
    int userId,
    Map<String, dynamic> endUserData,
  ) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.patch(
        '/end-users/user/$userId',
        data: endUserData,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Không thể cập nhật end-user profile: ${e.message}");
      return e.response;
    } catch (e) {
      print("Không thể cập nhật end-user profile (lỗi hệ thống): $e");
      return null;
    }
  }

  Future<Response?> updateUserAccount(
    int id,
    Map<String, dynamic> userData,
  ) async {
    try {
      final token = await _tokenService.getToken();
      final response = await _apiClient.dio.patch(
        '/users/$id',
        data: userData,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      print("Không thể cập nhật tài khoản: ${e.message}");
      return e.response;
    } catch (e) {
      print("Không thể cập nhật tài khoản (lỗi hệ thống): $e");
      return null;
    }
  }
}
