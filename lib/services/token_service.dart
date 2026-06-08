import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class tokenService {
  static const String _TOKEN_KEY = 'auth_token';
  static const String _USER_KEY = 'user_info';
  static const String _EXPIRY_KEY = 'token_expiry';

  Future<void> saveToken(String token, {int token_expiry = 164}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_TOKEN_KEY, token);

    final expiryTime = DateTime.now().add(Duration(hours: token_expiry));
    await prefs.setString(_EXPIRY_KEY, expiryTime.toIso8601String());

    print('✅ Token saved, expires at: $expiryTime');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_TOKEN_KEY);
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_EXPIRY_KEY);

    if (expiryStr == null) return true;

    final expiryTime = DateTime.parse(expiryStr);
    final isExpired = DateTime.now().isAfter(expiryTime);

    if (isExpired) {
      print('⚠️ Token expired at: $expiryTime');
    }

    return isExpired;
  }

  Future<bool> isSignIn() async {
    final token = await getToken();
    if (token == null) return false;
    final isExpired = await isTokenExpired();
    return !isExpired;
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_USER_KEY, jsonEncode(user));
  }

  // Lấy thông tin user
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_USER_KEY);
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  // Xóa toàn bộ (logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_TOKEN_KEY);
    await prefs.remove(_USER_KEY);
    await prefs.remove(_EXPIRY_KEY);
    print('🗑️ All tokens cleared');
  }

  // Lưu mục tiêu bước chân
  Future<void> saveTargetSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_steps', steps);
  }

  // Lấy mục tiêu bước chân (mặc định 10000)
  Future<int> getTargetSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('target_steps') ?? 10000;
  }
}
