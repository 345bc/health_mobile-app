import 'package:flutter/material.dart';
import 'package:frontend/screens/log_screen.dart';
import 'package:frontend/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  String _userName = '';
  int _currentSteps = 0;
  int _targetSteps = 10000;
  int _heartRate = 0;
  String _sleepTime = '';
  int _currentWater = 0;
  int _targetWater = 2000;

  @override
  void initState() {
    super.initState();
    _fetchDataFromApi();
  }

  Future<void> _fetchDataFromApi() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _userName = 'Minh Quân';
      _currentSteps = 7420;
      _heartRate = 72;
      _sleepTime = '7h 20m';
      _currentWater = 1250;
      _isLoading = false;
    });
  }

  void _addWater(int amount) {
    setState(() {
      if (_currentWater + amount <= _targetWater) {
        _currentWater += amount;
      } else {
        _currentWater = _targetWater;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSimpleHeader(),
                  const SizedBox(height: 24),
                  StepProgressCard(
                    current: _currentSteps,
                    target: _targetSteps,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: HeartRateCard(bpm: _heartRate)),
                      const SizedBox(width: 16),
                      Expanded(child: SleepCard(duration: _sleepTime)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WaterIntakeCard(
                    current: _currentWater,
                    target: _targetWater,
                    onAddWater: () =>
                        _addWater(250), // Truyền hàm xử lý xuống thẻ
                  ),
                  const SizedBox(height: 24),
                  const WorkoutBanner(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Phân tích tuần này'),
                  const SizedBox(height: 16),
                  const WeeklyAnalysisCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=tuantran'),
        ),
      ),
      title: const Text(
        'The Sanctuary',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSimpleHeader() {
    final hour = DateTime.now().hour;
    final String greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF0F75F4),
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),

        // Tên người dùng to, đậm
        Text(
          _userName.isEmpty ? 'Xin chào 👋' : '$_userName 👋',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

// ================= CÁC WIDGET CON (STATELESS) =================

// 1. Step Progress Card
class StepProgressCard extends StatelessWidget {
  final int current;
  final int target;

  const StepProgressCard({
    Key? key,
    required this.current,
    required this.target,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = current / target;
    int remaining = target - current;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BƯỚC CHÂN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_formatNumber(current)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${target ~/ 1000}k',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Còn ${_formatNumber(remaining)} bước nữa',
                  style: const TextStyle(
                    color: Color(0xFF198754),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0F75F4),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Icon(
                Icons.directions_walk,
                color: Color(0xFF0F75F4),
                size: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    // Hàm phụ trợ để hiển thị dấu phẩy hàng nghìn (ví dụ 7420 -> 7,420)
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// 2. Heart Rate Card
class HeartRateCard extends StatelessWidget {
  final int bpm;
  const HeartRateCard({Key? key, required this.bpm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildSmallCard(
      icon: Icons.favorite,
      iconColor: Colors.red,
      title: 'BPM',
      value: bpm.toString(),
      subtitle: 'Nhịp tim ổn định',
      bottomWidget: Container(
        height: 12,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.3),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Sleep Card
class SleepCard extends StatelessWidget {
  final String duration;
  const SleepCard({Key? key, required this.duration}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildSmallCard(
      icon: Icons.dark_mode,
      iconColor: Colors.orange,
      title: 'GIẤC NGỦ',
      value: duration,
      subtitle: 'Chất lượng: Tốt',
      bottomWidget: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index < 3 ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper for Small Cards
Widget _buildSmallCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String value,
  required String subtitle,
  required Widget bottomWidget,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4FA).withOpacity(0.5),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        bottomWidget,
      ],
    ),
  );
}

// 4. Water Intake Card
class WaterIntakeCard extends StatelessWidget {
  final int current;
  final int target;
  final VoidCallback onAddWater; // Nhận sự kiện bấm nút từ cha

  const WaterIntakeCard({
    Key? key,
    required this.current,
    required this.target,
    required this.onAddWater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format số
    String currentFormatted = current.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    String targetFormatted = target.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F75F4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LƯỢNG NƯỚC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F75F4),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: currentFormatted,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' / $targetFormatted ml',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAddWater, // Gọi hàm của cha khi bấm
            icon: const Icon(Icons.add, size: 18),
            label: const Text('250ml'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F75F4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Workout Banner (Tạm thời không cần state động)
class WorkoutBanner extends StatelessWidget {
  const WorkoutBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đã đến lúc cho\nmột bài tập giãn\ncơ nhẹ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chỉ cần 5 phút để giảm\ncăng thẳng cho cột sống\ncủa bạn.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCE4FF),
                foregroundColor: const Color(0xFF0F75F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Bắt đầu ngay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Weekly Analysis Card (Tạm thời không cần state động)
class WeeklyAnalysisCard extends StatelessWidget {
  const WeeklyAnalysisCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1F2D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up, color: Color(0xFF198754)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tăng trưởng vận động',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Bạn đã đi bộ nhiều hơn 12% so với tuần trước.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
