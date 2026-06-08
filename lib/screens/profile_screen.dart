import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/user-service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/models/end_user.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/screens/sign-in_screen.dart';
import 'package:frontend/screens/editprofile_screen.dart';
import 'package:frontend/screens/account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService(ApiService());
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
    final User? currentUser = userProvider.getUser();
    if (currentUser == null || currentUser.userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Gọi song song cả 2 API: thông tin tài khoản + hồ sơ cá nhân
      final results = await Future.wait([
        _userService.getUserById(currentUser.userId!),
        _userService.getEndUserProfile(currentUser.userId!),
      ]);

      final userResponse   = results[0];
      final profileResponse = results[1];

      // --- Merge thông tin từ /users/{id} ---
      String mergedEmail        = currentUser.email;
      String mergedName         = currentUser.user_name;
      String mergedPasswordHash = currentUser.passwordHash;

      if (userResponse != null && userResponse.statusCode == 200) {
        final raw = userResponse.data is String
            ? jsonDecode(userResponse.data as String)
            : userResponse.data as Map<String, dynamic>;
        final uData = (raw['data'] ?? raw) as Map<String, dynamic>;
        mergedEmail        = uData['email']        as String? ?? mergedEmail;
        mergedName         = (uData['name'] ?? uData['user_name']) as String? ?? mergedName;
        mergedPasswordHash = (uData['passwordHash'] ?? uData['password_hash']) as String? ?? mergedPasswordHash;
      }

      // --- Merge thông tin từ /end-users/user/{id} ---
      EndUser mergedEndUser = currentUser.endUser ?? EndUser(id: currentUser.userId, name: mergedName);

      if (profileResponse != null && profileResponse.statusCode == 200) {
        final raw = profileResponse.data is String
            ? jsonDecode(profileResponse.data as String)
            : profileResponse.data as Map<String, dynamic>;
        final pData = (raw['data'] ?? raw) as Map<String, dynamic>;
        final fetched = EndUser.fromMap(pData);
        // Merge: ưu tiên dữ liệu từ API, fallback về giá trị local
        mergedEndUser = EndUser(
          id:          fetched.id          ?? mergedEndUser.id,
          name:        fetched.name        ?? mergedName,
          dateOfBirth: fetched.dateOfBirth ?? mergedEndUser.dateOfBirth,
          gender:      fetched.gender      ?? mergedEndUser.gender,
          height:      fetched.height      ?? mergedEndUser.height,
          weight:      fetched.weight      ?? mergedEndUser.weight,
          bloodType:   fetched.bloodType   ?? mergedEndUser.bloodType,
          avatar:      fetched.avatar      ?? mergedEndUser.avatar,
        );
      }

      // Tạo User object đã cập nhật đầy đủ
      final updatedUser = User(
        userId:       currentUser.userId,
        email:        mergedEmail,
        passwordHash: mergedPasswordHash,
        user_name:    mergedName,
        endUser:      mergedEndUser,
      );

      // Lưu vào SQLite local
      await UserController().updateUser(updatedUser);

      // Cập nhật vào Provider để UI rebuild
      userProvider.setUser(updatedUser);

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
    final User? user = userProvider.getUser();

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
                      // Capture contexts and navigators before async call
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );

                      // Close the dialog using dialogContext
                      Navigator.pop(dialogContext);

                      // Logout from API
                      await _userService.logout();

                      // Clear session
                      userProvider.clearUser();

                      // Show success message
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Đã đăng xuất thành công."),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      // Redirect to login screen
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
  final User? user;

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
    final String displayName = user?.user_name ?? 'Chưa cập nhật';

    String displayAge = 'Chưa cập nhật tuổi';
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        final dob = DateTime.parse(user!.dateOfBirth!);
        final age = DateTime.now().year - dob.year;
        displayAge = '$age tuổi';
      } catch (_) {
        displayAge = user!.dateOfBirth!;
      }
    } else {
      displayAge = '';
    }

    final String displayBlood =
        user?.bloodType != null && user!.bloodType!.isNotEmpty
        ? 'Nhóm máu ${user!.bloodType}'
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
              backgroundImage: _buildAvatarImage(user?.avatar),
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
        const SizedBox(height: 4),
        Text(
          '$displayAge  •  $displayBlood',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C757D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class PersonalInfoCard extends StatelessWidget {
  final User? user;

  const PersonalInfoCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
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
                  value: user?.height != null
                      ? '${user!.height} cm'
                      : 'Chưa nhập',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.monitor_weight,
                  title: 'CÂN NẶNG',
                  value: user?.weight != null
                      ? '${user!.weight} kg'
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
                  value: user?.gender ?? 'Chưa nhập',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  title: 'NGÀY SINH',
                  value: user?.dateOfBirth ?? 'Chưa nhập',
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
                    icon: Icons.notifications_none,
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
