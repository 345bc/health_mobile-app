import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF), // Nền xám/xanh siêu nhạt

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                "Tạo tài khoản mới",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Khởi đầu hành trình chăm sóc sức khỏe toàn diện\ncủa bạn trong không gian yên bình.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              _buildLabel("HỌ VÀ TÊN"),
              _buildTextField("Nguyễn Văn A"),
              const SizedBox(height: 16),

              _buildLabel("EMAIL"),
              _buildTextField("example@vitalis.com"),
              const SizedBox(height: 16),

              _buildLabel("MẬT KHẨU"),
              _buildTextField("••••••••", isPassword: true),
              const SizedBox(height: 16),

              _buildLabel("XÁC NHẬN MẬT KHẨU"),
              _buildTextField("••••••••", isPassword: true),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: false,
                      onChanged: (v) {},
                      activeColor: const Color(0xFF0F75F4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        children: const [
                          TextSpan(text: "Tôi đồng ý với "),
                          TextSpan(
                            text: "Điều khoản & Chính sách",
                            style: TextStyle(
                              color: Color(0xFF0F75F4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Nút Đăng ký chính
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Đăng ký",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 28),

              // 5. Đường kẻ phân cách
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey[300], thickness: 1),
                  ),

                  Expanded(
                    child: Divider(color: Colors.grey[300], thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LoginScreen();
                        },
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      children: const [
                        TextSpan(text: "Đã có tài khoản? "),
                        TextSpan(
                          text: "Đăng nhập",
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

  // Hàm tạo Label (Tiêu đề nhỏ trên mỗi ô nhập)
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Hàm tạo Ô nhập liệu (TextField)
  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(
          0xFFF0F1F5,
        ), // Màu xám nhạt đặc trưng của iOS/App sức khỏe
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Bỏ viền đen mặc định
        ),
      ),
    );
  }

  // Hàm tạo Nút Social (Google/Apple)
  Widget _buildSocialButton(String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.black, size: 24),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1.5,
        ), // Viền xám rất nhạt
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
