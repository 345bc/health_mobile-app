import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/models/end_user.dart';
import 'package:frontend/screens/sign-up_screen.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/services/user-service.dart';
import 'package:frontend/services/api_service.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final ApiService apiService = ApiService();
  late final UserService userService = UserService(apiService);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserController _userController = UserController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ email và mật khẩu."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await userService.signin(email, password);

      if (response?.statusCode == 200) {
        final data = response?.data['data'];
        final userData = data['user'];

        User? existingUser;
        try {
          existingUser = await _userController.getUserByEmail(email);
        } catch (dbError) {
          debugPrint("Lỗi đọc SQLite khi đăng nhập: $dbError");
        }
        final int serverId = userData['id'];

        if (!mounted) return;

        // Đồng bộ thêm thông tin EndUser (chiều cao, cân nặng, giới tính, nhóm máu...) từ server về SQLite & Provider
        User finalUser = existingUser != null 
            ? existingUser.copyWith(userId: serverId)
            : User(
                userId: serverId,
                email: email,
                passwordHash: password,
                user_name: userData['name'],
              );

        try {
          final profileResponse = await userService.getEndUserProfile(serverId);
          if (profileResponse != null && profileResponse.statusCode == 200) {
            final Map<String, dynamic> responseData = profileResponse.data is String
                ? jsonDecode(profileResponse.data)
                : profileResponse.data as Map<String, dynamic>;

            final dynamic profileData = responseData['data'] ?? responseData;
            if (profileData is Map<String, dynamic>) {
              final endUserObj = EndUser.fromMap(profileData);
              finalUser = finalUser.copyWith(endUser: endUserObj);
            }
          }
        } catch (profileError) {
          debugPrint("Lỗi đồng bộ hồ sơ chi tiết khi đăng nhập: $profileError");
        }

        // Lưu/Cập nhật thông tin hoàn chỉnh (gồm cả EndUser nếu có) vào SQLite
        try {
          if (existingUser != null) {
            if (existingUser.userId != serverId) {
              await _userController.deleteUser(existingUser.userId!);
              await _userController.insertUser(finalUser);
            } else {
              await _userController.updateUser(finalUser);
            }
          } else {
            await _userController.insertUser(finalUser);
          }
        } catch (dbError) {
          debugPrint("Lỗi lưu user đầy đủ vào SQLite: $dbError");
        }

        // Đồng bộ nhắc nhở từ server xuống SQLite
        try {
          await WaterController().refreshRemindersFromServer(serverId);
        } catch (reminderError) {
          debugPrint("Lỗi đồng bộ nhắc nhở khi đăng nhập: $reminderError");
        }

        if (!mounted) return;
        Provider.of<UserProvider>(context, listen: false).setUser(finalUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công! 🎉')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Lỗi đăng nhập xảy ra: $e");
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      if (e is DioException) {
        // Nếu có phản hồi lỗi từ server dưới dạng JSON map
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final Map<String, dynamic> errorData =
              e.response!.data as Map<String, dynamic>;
          final String serverMessage =
              errorData['message'] ?? 'Đã xảy ra lỗi khi đăng nhập';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(serverMessage),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Các trường hợp lỗi mạng/máy chủ khác: thử đăng nhập ngoại tuyến
        User? offlineUser;
        try {
          offlineUser = await _userController.getUserByEmail(email);
        } catch (dbError) {
          debugPrint("Lỗi đọc SQLite khi offline: $dbError");
        }
        if (!mounted) return;

        if (offlineUser != null) {
          if (offlineUser.passwordHash == password) {
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).setUser(offlineUser);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đang chạy ở chế độ ngoại tuyến (Offline)"),
                backgroundColor: Colors.blueGrey,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
            return;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Sai mật khẩu (Chế độ ngoại tuyến)"),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Không có kết nối mạng hoặc máy chủ và tài khoản chưa được lưu trên thiết bị này!",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      String fallbackMessage = 'Đã xảy ra lỗi hệ thống khi đăng nhập';
      if (e is Map<String, dynamic>) {
        fallbackMessage = e['message'] ?? fallbackMessage;
      } else {
        fallbackMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Chào mừng trở lại",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Tiếp tục hành trình chăm sóc sức khỏe của\nbạn cùng chúng tôi.",
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Form Nhập liệu: Email
              _buildLabelRow("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "example@gmail.com",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Form Nhập liệu: Mật khẩu
              _buildLabelRow("Password"),
              _buildTextField(
                controller: _passwordController,
                hint: "••••••••",
                prefixIcon: Icons.lock_outline,
                isPassword: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onSuffixIconPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Nút Đăng nhập
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F75F4).withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      children: const [
                        TextSpan(text: "Bạn chưa có tài khoản? "),
                        TextSpan(
                          text: "Đăng ký ngay",
                          style: TextStyle(
                            color: Color(0xFF0F75F4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF0F1F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: Colors.grey[600]),
                onPressed: onSuffixIconPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
