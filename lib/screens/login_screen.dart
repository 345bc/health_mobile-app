import 'package:flutter/material.dart';
import 'package:frontend/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
              Row(children: [const SizedBox(width: 12)]),
              const SizedBox(height: 40),

              // 2. Lời chào
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

              // 3. Form Nhập liệu: Email
              _buildLabelRow("Email"),
              _buildTextField(
                hint: "ten@email.com",
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // 4. Form Nhập liệu: Mật khẩu (Có nút Quên mật khẩu)
              _buildLabelRow("Mật khẩu", trailingText: "Quên mật khẩu?"),
              _buildTextField(
                hint: "••••••••",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                suffixIcon: Icons.visibility_outlined,
              ),
              const SizedBox(height: 32),

              // 5. Nút Đăng nhập
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F75F4).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 250),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const SignUpScreen();
                        },
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

  // --- CÁC HÀM XÂY DỰNG WIDGET DÙNG CHUNG ---

  // Hàm tạo dòng Label (Hỗ trợ nút "Quên mật khẩu" bên phải)
  Widget _buildLabelRow(String text, {String? trailingText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          if (trailingText != null)
            GestureDetector(
              onTap: () {},
              child: Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F75F4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Hàm tạo Ô nhập liệu (Hỗ trợ Prefix và Suffix Icon)
  Widget _buildTextField({
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    IconData? suffixIcon,
  }) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF0F1F5), // Xám nhạt
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]), // Icon bên trái
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[600])
            : null, // Icon bên phải
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
