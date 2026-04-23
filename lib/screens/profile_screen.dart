import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            const ProfileHeader(),
            const SizedBox(height: 24),
            const PersonalInfoCard(),
            const SizedBox(height: 32),
            const AppSettingsSection(),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {},
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
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4), // Độ dày của viền
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
        const Text(
          'Lê Minh Anh',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '26 tuổi  •  Nhóm máu O+',
          style: TextStyle(
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
  const PersonalInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB), // Xám nhạt hơi ám xanh
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
                  value: '165 cm',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.monitor_weight,
                  title: 'CÂN NẶNG',
                  value: '58.2 kg',
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
                  value: 'Nữ',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  title: 'NGÀY SINH',
                  value: '15/05/1998',
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

// 3. Phần Mục tiêu sức khỏe
class HealthGoalsSection extends StatelessWidget {
  const HealthGoalsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mục tiêu sức khỏe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Chỉnh sửa',
                style: TextStyle(
                  color: Color(0xFF0F75F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildGoalCard(
          icon: Icons.directions_walk,
          iconBg: const Color(0xFFE7F1FF),
          iconColor: const Color(0xFF0F75F4),
          title: 'BƯỚC CHÂN',
          value: '10,000',
          unit: 'bước',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1F2D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+12%',
              style: TextStyle(
                color: Color(0xFF198754),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildGoalCard(
          icon: Icons.water_drop,
          iconBg: const Color(0xFFE7F1FF),
          iconColor: const Color(0xFF0F75F4),
          title: 'NƯỚC UỐNG',
          value: '2.5 Lít',
          unit: '/ ngày',
        ),
        const SizedBox(height: 12),
        _buildGoalCard(
          icon: Icons.track_changes,
          iconBg: const Color(0xFFFFF0E6),
          iconColor: const Color(0xFFFD7E14),
          title: 'CÂN NẶNG ĐÍCH',
          value: '52.0 kg',
          unit: '',
          trailing: const Text(
            '-3.5kg',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEBECEE),
          width: 1.5,
        ), // Viền nhạt
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6C757D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0xFF111111)),
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

// 4. Phần Cài đặt ứng dụng
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({Key? key}) : super(key: key);

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
              _buildSettingItem(
                icon: Icons.watch,
                title: 'Kết nối thiết bị',
                // subtitle: 'Apple Watch đang kết nối',
              ),
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
