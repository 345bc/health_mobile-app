import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';

import 'package:frontend/screens/sign-in_screen.dart';
import 'package:frontend/screens/editprofile_screen.dart';
import 'package:frontend/screens/account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.getUser();
    if (currentUser == null) return;
    final int userId = currentUser['id'] ?? currentUser['userId'] ?? 0;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getUserById(userId),
        ApiService.getEndUserProfile(userId),
      ]);

      final userResponse = results[0];
      final profileResponse = results[1];

      final Map<String, dynamic> mergedUser = Map.from(currentUser);

      if (userResponse != null) {
        final uData = (userResponse['data'] ?? userResponse) as Map<String, dynamic>;
        mergedUser['email'] = uData['email'] ?? mergedUser['email'];
        mergedUser['name'] = uData['name'] ?? uData['user_name'] ?? mergedUser['name'];
        mergedUser['passwordHash'] = uData['passwordHash'] ?? uData['password_hash'] ?? mergedUser['passwordHash'];
      }

      if (profileResponse != null) {
        final pData = (profileResponse['data'] ?? profileResponse) as Map<String, dynamic>;
        mergedUser['dateOfBirth'] = pData['dateOfBirth'] ?? pData['date_of_birth'] ?? mergedUser['dateOfBirth'];
        mergedUser['gender'] = pData['gender'] ?? mergedUser['gender'];
        mergedUser['height'] = pData['height'] ?? mergedUser['height'];
        mergedUser['weight'] = pData['weight'] ?? mergedUser['weight'];
        mergedUser['bloodType'] = pData['bloodType'] ?? pData['blood_type'] ?? mergedUser['bloodType'];
        mergedUser['avatar'] = pData['avatar'] ?? mergedUser['avatar'];
      }

      userProvider.setUser(mergedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã đồng bộ hồ sơ từ máy chủ.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi đồng bộ hồ sơ: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không thể kết nối máy chủ. Hiển thị dữ liệu ngoại tuyến."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        automaticallyImplyLeading: false,
        title: const Text(
          'Hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F75F4)),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _fetchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F75F4)))
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              color: const Color(0xFF0F75F4),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    ProfileHeader(user: user),
                    const SizedBox(height: 24),
                    PersonalInfoCard(user: user),
                    const SizedBox(height: 32),
                    const AppSettingsSection(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text("Đăng xuất"),
                content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );

                      Navigator.pop(dialogContext);

                      // Clear tokens and preferences
                      await tokenService().clearAll();

                      // Clear session in provider
                      userProvider.clearUser();

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Đã đăng xuất thành công."),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const SigninScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Đồng ý'),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFFFF0F0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfileHeader({super.key, this.user});

  ImageProvider _buildAvatarImage(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/profile-image.jpg');
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = user?['name'] ?? user?['user_name'] ?? 'Chưa cập nhật';
    final String? dobStr = user?['dateOfBirth'] ?? user?['date_of_birth'];

    String displayAge = 'Chưa cập nhật tuổi';
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobStr);
        final age = DateTime.now().year - dob.year;
        displayAge = '$age tuổi';
      } catch (_) {
        displayAge = dobStr;
      }
    } else {
      displayAge = '';
    }

    final String? bloodType = user?['bloodType'] ?? user?['blood_type'];
    final String displayBlood =
        bloodType != null && bloodType.isNotEmpty
        ? 'Nhóm máu $bloodType'
        : '';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundImage: _buildAvatarImage(user?['avatar'] as String?),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        if (displayAge.isNotEmpty || displayBlood.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${displayAge.isNotEmpty ? displayAge : ''}${displayAge.isNotEmpty && displayBlood.isNotEmpty ? '  •  ' : ''}${displayBlood.isNotEmpty ? displayBlood : ''}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class PersonalInfoCard extends StatelessWidget {
  final Map<String, dynamic>? user;

  const PersonalInfoCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final double? heightVal = user?['height'] != null ? (user!['height'] as num).toDouble() : null;
    final double? weightVal = user?['weight'] != null ? (user!['weight'] as num).toDouble() : null;
    final String? gender = user?['gender'];
    final String? dob = user?['dateOfBirth'] ?? user?['date_of_birth'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN CÁ NHÂN',
            style: TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.height,
                  title: 'CHIỀU CAO',
                  value: heightVal != null
                      ? '$heightVal cm'
                      : 'Chưa nhập',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.monitor_weight,
                  title: 'CÂN NẶNG',
                  value: weightVal != null
                      ? '$weightVal kg'
                      : 'Chưa nhập',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person,
                  title: 'GIỚI TÍNH',
                  value: gender ?? 'Chưa nhập',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  title: 'NGÀY SINH',
                  value: dob ?? 'Chưa nhập',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F75F4), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111111),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt ứng dụng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBECEE), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.5),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Hồ sơ cá nhân',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEBECEE),
                    indent: 56,
                  ),
                  _buildSettingItem(
                    icon: Icons.lock_outline,
                    title: 'Tài khoản',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    VoidCallback? onTap,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      splashColor: Colors.blue.withValues(alpha: 0.3),
      hoverColor: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C757D), size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFADB5BD),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFADB5BD)),
          ],
        ),
      ),
    );
  }
}
