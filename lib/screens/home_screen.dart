import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/activity.dart';
import 'package:frontend/data/models/sleep_log.dart';
import 'package:frontend/screens/activity_screen.dart';
import 'package:frontend/screens/sleep_screen.dart';
import 'package:frontend/screens/nutrition_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  final DatabaseHelper _db = DatabaseHelper();

  // Stats đọc từ SQLite
  int _steps = 0;
  int _targetSteps = 10000;
  int _caloriesBurned = 0;
  int? _heartRate;
  String _sleepText = '--';
  int _currentWater = 0;
  final int _targetWater = 2000;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    if (!mounted) return;
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final int userId = user.userId ?? 0;

    // Đọc song song từ DB
    final results = await Future.wait([
      _db.getTodayActivity(userId),
      _db.getLastSleep(userId),
      _db.getLatestHeartRate(userId),
      _db.getLatestBodyMeasurement(userId),
    ]);

    if (!mounted) return;

    final Activity? activity = results[0] as Activity?;
    final SleepLog? sleep = results[1] as SleepLog?;
    final int? heartRate = results[2] as int?;

    setState(() {
      _steps = activity?.steps ?? 0;
      _caloriesBurned = activity?.caloriesBurned ?? 0;
      _heartRate = heartRate;
      _sleepText = sleep?.durationFormatted ?? '--';
      _isLoading = false;
    });
  }

  void _addWater(int amount) {
    setState(() {
      _currentWater = (_currentWater + amount).clamp(0, _targetWater);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser();
    final String name = user?.name ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(name),
                    const SizedBox(height: 24),

                    // Bước chân
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActivityScreen(),
                        ),
                      ).then((_) => _loadStats()),
                      child: StepProgressCard(
                        current: _steps,
                        target: _targetSteps,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nhịp tim & Giấc ngủ
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: HeartRateCard(bpm: _heartRate),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SleepScreen(),
                              ),
                            ).then((_) => _loadStats()),
                            child: SleepCard(duration: _sleepText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nước uống
                    WaterIntakeCard(
                      current: _currentWater,
                      target: _targetWater,
                      onAddWater: () => _addWater(250),
                    ),
                    const SizedBox(height: 24),

                    // Calo đốt hôm nay
                    _buildCalorieCard(),
                    const SizedBox(height: 24),

                    // Banner dinh dưỡng
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NutritionScreen(),
                        ),
                      ),
                      child: const WorkoutBanner(),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Phân tích tuần này'),
                    const SizedBox(height: 16),
                    const WeeklyAnalysisCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
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
        Text(
          name.isEmpty ? 'Xin chào 👋' : '$name 👋',
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

  Widget _buildCalorieCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CALO ĐỐT HÔM NAY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_caloriesBurned kcal',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A1A1A),
    ),
  );
}

// ===== WIDGETS CON =====

class StepProgressCard extends StatelessWidget {
  final int current;
  final int target;
  const StepProgressCard({
    super.key,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
    final int remaining = (target - current).clamp(0, target);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
                        text: _fmt(current),
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
                  current == 0
                      ? 'Chưa ghi nhận hôm nay'
                      : 'Còn ${_fmt(remaining)} bước nữa',
                  style: TextStyle(
                    color: current == 0 ? Colors.grey : const Color(0xFF198754),
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

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

class HeartRateCard extends StatelessWidget {
  final int? bpm;
  const HeartRateCard({super.key, this.bpm});

  @override
  Widget build(BuildContext context) {
    return _buildSmallCard(
      icon: Icons.favorite,
      iconColor: Colors.red,
      title: 'BPM',
      value: bpm != null ? bpm.toString() : '--',
      subtitle: bpm != null ? 'Nhịp tim ổn định' : 'Chưa đo',
      bottomWidget: Container(
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0x4D2196F3), Color(0x1A2196F3)],
          ),
        ),
      ),
    );
  }
}

class SleepCard extends StatelessWidget {
  final String duration;
  const SleepCard({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return _buildSmallCard(
      icon: Icons.dark_mode,
      iconColor: Colors.orange,
      title: 'GIẤC NGỦ',
      value: duration,
      subtitle: duration == '--' ? 'Chưa ghi' : 'Chạm để xem',
      bottomWidget: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < 3 ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      color: const Color(0xFFF1F4FA).withAlpha(128),
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

class WaterIntakeCard extends StatelessWidget {
  final int current;
  final int target;
  final VoidCallback onAddWater;

  const WaterIntakeCard({
    super.key,
    required this.current,
    required this.target,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
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
                        text: fmt(current),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${fmt(target)} ml',
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
            onPressed: onAddWater,
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

class WorkoutBanner extends StatelessWidget {
  const WorkoutBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [Colors.black.withAlpha(178), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dinh dưỡng hôm nay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chạm để ghi nhận bữa ăn và theo dõi calo.',
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCE4FF),
                foregroundColor: const Color(0xFF0F75F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Xem dinh dưỡng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyAnalysisCard extends StatelessWidget {
  const WeeklyAnalysisCard({super.key});

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
                  'Ghi nhận vận động hàng ngày để xem thống kê.',
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
