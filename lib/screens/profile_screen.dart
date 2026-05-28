import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/screens/sign-in_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final User? user = userProvider.getUser();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
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
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          // Clear active user session
          Provider.of<UserProvider>(context, listen: false).clearUser();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã đăng xuất thành công."),
              backgroundColor: Colors.green,
            ),
          );

          // Redirect to login screen, clearing navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SigninScreen()),
            (route) => false,
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

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.user_name ?? '';
    final String displayAge = user != null
        ? '26 tuổi'
        : '26 tuổi'; // Mocks/Default age
    final String displayBlood = 'Nhóm máu O+';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=11'),
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
    // // Determine info based on database user
    // final String gender = user?.gender == 'Female'
    //     ? 'Nữ'
    //     : (user?.gender == 'Male' ? 'Nam' : 'Khác');
    // final String dob = user?.dateOfBirth ?? '15/05/1998';
    // final String height = '165 cm';
    // final String weight = '58.2 kg';

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
                  value: "height",
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.monitor_weight,
                  title: 'CÂN NẶNG',
                  value: "weight",
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
                  value: "nuwx",
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  title: 'NGÀY SINH',
                  value: "10",
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBECEE), width: 1.5),
          ),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.notifications_none,
                title: 'Thông báo',
              ),
              const Divider(height: 1, color: Color(0xFFEBECEE), indent: 56),
              _buildSettingItem(icon: Icons.watch, title: 'Kết nối thiết bị'),
              const Divider(height: 1, color: Color(0xFFEBECEE), indent: 56),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'Bảo mật & Riêng tư',
              ),
              const Divider(height: 1, color: Color(0xFFEBECEE), indent: 56),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Trợ giúp & Hỗ trợ',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF6C757D), size: 26),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111111),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFADB5BD)),
      onTap: () {},
    );
  }
}
