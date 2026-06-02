import 'package:flutter/material.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/services/user-service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/notification_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final User? user = userProvider.getUser();

    _usernameController = TextEditingController(text: user?.user_name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveAccountDetails() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.getUser();

      if (currentUser != null && currentUser.userId != null) {
        setState(() {
          _isLoading = true;
        });

        final Map<String, dynamic> patchData = {
          'name': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          if (_passwordController.text.isNotEmpty)
            'passwordHash': _passwordController.text,
        };

        bool isSavedOnServer = false;
        bool isOffline = false;
        String errorMessage = "Đã xảy ra lỗi khi lưu thông tin tài khoản.";

        try {
          final ApiService apiService = ApiService();
          final UserService userService = UserService(apiService);

          final response = await userService.updateUserAccount(
            currentUser.userId!,
            patchData,
          );

          if (response != null) {
            if (response.statusCode == 200 || response.statusCode == 201) {
              isSavedOnServer = true;
            } else {
              isSavedOnServer = false;
              final responseData = response.data;
              if (responseData is Map<String, dynamic> &&
                  responseData.containsKey('message')) {
                errorMessage = responseData['message'];
              } else {
                errorMessage = "Lỗi máy chủ (${response.statusCode})";
              }
            }
          } else {
            isOffline = true;
          }
        } catch (e) {
          print("Lỗi khi cập nhật tài khoản lên server: $e");
          isOffline = true;
        }

        if (isSavedOnServer || isOffline) {
          // Construct updated user object
          final updatedUser = currentUser.copyWith(
            user_name: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            passwordHash: _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
          );

          // Update in SQLite
          final UserController userController = UserController();
          await userController.updateUser(updatedUser);

          // Update in Provider
          userProvider.setUser(updatedUser);

          setState(() {
            _isLoading = false;
          });

          if (isSavedOnServer) {
            NotificationService().showNotification(
              id: 10,
              title: "Cập nhật tài khoản",
              body: "Thông tin tài khoản đăng nhập đã được thay đổi thành công.",
            );
          } else {
            NotificationService().showNotification(
              id: 11,
              title: "Lưu tạm thời (Offline)",
              body: "Đã lưu tài khoản cục bộ. Không thể kết nối tới máy chủ.",
            );
          }

          if (!mounted) return;
          Navigator.pop(context);
        } else {
          setState(() {
            _isLoading = false;
          });
          NotificationService().showNotification(
            id: 12,
            title: "Cập nhật thất bại",
            body: errorMessage,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSectionTitle('THÔNG TIN ĐĂNG NHẬP'),
              const SizedBox(height: 16),

              // Username input
              _buildTextField(
                controller: _usernameController,
                label: 'Tên tài khoản (Username)',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên tài khoản';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email input
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Địa chỉ email không đúng định dạng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('THAY ĐỔI MẬT KHẨU'),
              const SizedBox(height: 16),

              // New Password input
              _buildTextField(
                controller: _passwordController,
                label: 'Mật khẩu mới (Bỏ trống nếu không đổi)',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF6C757D),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password input
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu mới',
                icon: Icons.lock_clock_outlined,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF6C757D),
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Vui lòng xác nhận lại mật khẩu mới';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không trùng khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccountDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75F4),
                    foregroundColor: Colors.white,
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
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6C757D),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111111),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C757D), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F75F4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
