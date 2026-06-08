import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/models/end_user.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/user-service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/sign-in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  final UserService _userService = UserService(ApiService());

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {
        _progress = _controller.value;
      });
    });

    //animation mờ dần
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // animation phóng to
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    //animation trượt lên
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    try {
      final checkLoginFuture = _userService.isLoggedIn();

      // Chạy animation và đợi cho đến khi hoàn tất (3 giây)
      await _controller.forward();

      final isLoggedIn = await checkLoginFuture;

      if (isLoggedIn) {
        final userMap = await _userService.getCurrentUser();
        if (userMap != null && mounted) {
          User user = User.fromJson(userMap);
          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // Đồng bộ thông tin EndUser (chiều cao, cân nặng, giới tính...) từ server xuống SQLite & Provider
          try {
            final profileResponse = await _userService.getEndUserProfile(user.userId!);
            if (profileResponse != null && profileResponse.statusCode == 200) {
              final Map<String, dynamic> responseData = profileResponse.data is String
                  ? jsonDecode(profileResponse.data)
                  : profileResponse.data as Map<String, dynamic>;

              final dynamic data = responseData['data'] ?? responseData;
              if (data is Map<String, dynamic>) {
                final updatedUser = user.copyWith(
                  endUser: EndUser.fromMap(data),
                );
                // Cập nhật SQLite
                await UserController().updateUser(updatedUser);
                // Cập nhật Provider
                if (mounted) {
                  Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);
                }
              }
            }
          } catch (e) {
            debugPrint("Lỗi đồng bộ hồ sơ khi khởi động: $e");
          }

          // Đồng bộ nhắc nhở từ server xuống SQLite
          try {
            await WaterController().refreshRemindersFromServer(user.userId!);
          } catch (e) {
            debugPrint("Lỗi đồng bộ nhắc nhở khi khởi động: $e");
          }
        }
      }

      if (mounted) {
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SigninScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin đăng nhập: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SigninScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.lightBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(child: FlutterLogo(size: 56)),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Health App',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chăm sóc sức khỏe của bạn',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(200),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white.withAlpha(230),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withAlpha(50),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
