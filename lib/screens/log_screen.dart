import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  DateTime _selectedDate = DateTime.now();
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogHeader(),
              const SizedBox(height: 32),

              const Text(
                'CHỌN MỤC GHI CHÉP',
                style: TextStyle(
                  color: Color(0xFF495057),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const CategoryGrid(),

              const SizedBox(height: 32),
              ProgressCard(ontap: () => _selectDate()),

              const SizedBox(height: 24),
              const AdviceCard(),

              const SizedBox(height: 24),
              const QuoteBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class LogHeader extends StatelessWidget {
  const LogHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ghi chép chỉ số',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// 2. Lưới Thẻ chọn mục ghi chép
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.monitor_weight_outlined,
                iconColor: const Color(0xFF0F75F4),
                title: 'Cân nặng',
                subtitle: '68.5 KG',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.speed, // Dùng icon speed mô phỏng huyết áp
                iconColor: const Color(0xFF198754),
                title: 'Huyết áp',
                subtitle: '120/80 MMHG',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.restaurant,
                iconColor: const Color(0xFFD97706),
                title: 'Món ăn',
                subtitle: 'ĐÃ GHI 3 BỮA',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.sentiment_satisfied_alt,
                iconColor: const Color(0xFFDC3545),
                title: 'Tâm trạng',
                subtitle: 'RẤT TỐT',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBECEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C757D),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final VoidCallback? ontap;
  const ProgressCard({super.key, this.ontap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            'Streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),

          Stack(
            alignment: Alignment.center,
            children: [
              // SizedBox(
              //   width: 120,
              //   height: 120,
              //   child: CircularProgressIndicator(
              //     value: 0.8, // 80%
              //     strokeWidth: 12,
              //     backgroundColor: Colors.white,
              //     valueColor: const AlwaysStoppedAnimation<Color>(
              //       Color(0xFF0F75F4),
              //     ),
              //     strokeCap: StrokeCap.round,
              //   ),
              // ),
              Column(
                children: const [
                  Text(
                    '80',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'NGÀY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tuần này',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: ontap,
                borderRadius: BorderRadius.circular(10),
                child: _buildDateTracker(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Biểu đồ cột mini (Tự vẽ bằng Container)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('T2', 0.4, false),
              _buildBar('T3', 0.5, false),
              _buildBar('T4', 0.6, false),
              _buildBar('T5', 0.45, false),
              _buildBar('T6', 0.7, false),
              _buildBar('T7', 0.55, false),
              _buildBar('CN', 1.0, true), // Cột cao nhất, đang active
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTracker() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE, d MMMM').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedDate,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF0F75F4),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double heightFactor, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 60 * heightFactor,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F75F4) : const Color(0xFFAECBFA),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF0F75F4) : const Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }
}

// 4. Thẻ Lời khuyên
class AdviceCard extends StatelessWidget {
  const AdviceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF9D5B15), // Màu nâu đồng
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'LỜI KHUYÊN HÔM NAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Uống một ly nước ấm ngay sau khi thức dậy.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Giúp kích hoạt hệ tiêu hóa và đào thải độc tố tích tụ qua đêm.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Ảnh Quote truyền cảm hứng
class QuoteBanner extends StatelessWidget {
  const QuoteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomCenter,
        child: const Text(
          '"Sức khỏe là thành quả của những thói quen nhỏ mỗi ngày."',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057),
          ),
        ),
      ),
    );
  }
}
