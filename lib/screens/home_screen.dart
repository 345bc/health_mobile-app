import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/screens/activity_screen.dart';
import 'package:frontend/screens/sleep_screen.dart';
import 'package:frontend/screens/nutrition_screen.dart';
import 'package:frontend/screens/vitals_screen.dart';
import 'package:frontend/screens/water_screen.dart';
import 'package:frontend/screens/analytics_screen.dart';
import 'package:frontend/services/token_service.dart';
import 'package:frontend/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _steps = 0;
  int _targetSteps = 10000;
  int _caloriesBurned = 0;
  int? _heartRate;
  String _sleepText = '--';
  int _todayWater = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final int userId = user['id'] ?? user['userId'] ?? 0;

    try {
      final results = await Future.wait([
        ApiService.getActivitiesByUser(userId),
        ApiService.getSleepsByUser(userId),
        ApiService.getBodyMeasurementsByUser(userId),
        ApiService.getTodayTotalWater(userId),
        tokenService().getTargetSteps(),
      ]);
      if (!mounted) return;

      final List<dynamic> activities = results[0] as List<dynamic>;
      final List<dynamic> sleeps = results[1] as List<dynamic>;
      final List<dynamic> measurements = results[2] as List<dynamic>;
      final Map<String, dynamic>? todayWaterResponse = results[3] as Map<String, dynamic>?;
      final int targetSteps = results[4] as int;

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      Map<String, dynamic>? todayActivity;
      for (var act in activities) {
        if (act['date'] == todayStr) {
          todayActivity = act;
          break;
        }
      }

      Map<String, dynamic>? lastSleep;
      if (sleeps.isNotEmpty) {
        final sortedSleeps = List.from(sleeps);
        sortedSleeps.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
        lastSleep = sortedSleeps.first;
      }

      int? heartRate;
      if (measurements.isNotEmpty) {
        final sortedMeasurements = List.from(measurements);
        sortedMeasurements.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
        for (var m in sortedMeasurements) {
          if (m['heartRate'] != null || m['heart_rate'] != null) {
            heartRate = (m['heartRate'] ?? m['heart_rate']) as int;
            break;
          }
        }
      }

      final int todayWater = todayWaterResponse != null && todayWaterResponse['data'] != null
          ? (todayWaterResponse['data'] as int)
          : 0;

      String sleepText = '--';
      if (lastSleep != null && (lastSleep['duration'] != null || lastSleep['duration_minutes'] != null)) {
        final int dur = lastSleep['duration'] ?? lastSleep['duration_minutes'] ?? 0;
        final h = dur ~/ 60;
        final m = dur % 60;
        if (h == 0) {
          sleepText = '${m}m';
        } else if (m == 0) {
          sleepText = '${h}h';
        } else {
          sleepText = '${h}h ${m}m';
        }
      }

      setState(() {
        _steps = todayActivity != null ? (todayActivity['steps'] ?? 0) : 0;
        _caloriesBurned = todayActivity != null ? (todayActivity['caloriesBurned'] ?? todayActivity['calories_burned'] ?? 0) : 0;
        _heartRate = heartRate;
        _sleepText = sleepText;
        _todayWater = todayWater;
        _targetSteps = targetSteps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load server error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "").trim();
        _isLoading = false;
      });
      return;
    }

    // _syncFromServer(userId);

    // final results = await Future.wait([
    //   _db.getTodayActivity(userId),
    //   _db.getLastSleep(userId),
    //   _db.getLatestHeartRate(userId),
    //   _db.getLatestBodyMeasurement(userId),
    //   _db.getTodayTotalWater(userId),
    // ]);

    // if (!mounted) return;

    // final Activity? activity = results[0] as Activity?;
    // final SleepLog? sleep = results[1] as SleepLog?;
    // final int? heartRate = results[2] as int?;
    // final int todayWater = results[4] as int;

    // int targetSteps = 10000;

    // setState(() {
    //   _steps = activity?.steps ?? 0;
    //   _caloriesBurned = activity?.caloriesBurned ?? 0;
    //   _heartRate = heartRate;
    //   _sleepText = sleep?.durationFormatted ?? '--';
    //   _targetSteps = targetSteps;
    //   _todayWater = todayWater;
    //   _isLoading = false;
    // });
  }

  // Future<void> _syncFromServer(int userId) async {
  //   try {
  //     final results = await Future.wait([
  //       _api.getTodayActivity(userId),
  //       _api.getLastSleep(userId),
  //       _api.getLatestHeartRate(userId),
  //       _api.getLatestBodyMeasurement(userId),
  //       _api.getTodayTotalWater(userId),
  //     ]);

  //     // Lưu xuống local
  //     await Future.wait([
  //       _db.saveTodayActivity(results[0] as Activity?),
  //       _db.saveLastSleep(results[1] as SleepLog?),
  //       _db.saveLatestHeartRate(results[2] as int?),
  //       _db.saveLatestBodyMeasurement(results[3] as BodyMeasurement?),
  //       _db.saveTodayTotalWater(results[4] as int?),
  //     ]);

  //     if (!mounted) return;

  //     // Cập nhật UI với data mới nhất
  //     final Activity? activity = results[0] as Activity?;
  //     final SleepLog? sleep = results[1] as SleepLog?;
  //     final int? heartRate = results[2] as int?;
  //     final int todayWater = (results[4] as int?) ?? 0;

  //     setState(() {
  //       _steps = activity?.steps ?? 0;
  //       _caloriesBurned = activity?.caloriesBurned ?? 0;
  //       _heartRate = heartRate;
  //       _sleepText = sleep?.durationFormatted ?? '--';
  //       _todayWater = todayWater;
  //     });
  //   } catch (e) {
  //     // Mất mạng hoặc server lỗi → giữ nguyên local data, không crash
  //     debugPrint('Sync API error: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser();
    final String name = user?['username'] ?? user?['name'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Có lỗi kết nối xảy ra',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F75F4),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadData,
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
                      ).then((_) => _loadData()),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const VitalsScreen(initialTab: 3),
                                ),
                              ).then((_) => _loadData());
                            },
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
                            ).then((_) => _loadData()),
                            child: SleepCard(duration: _sleepText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calo đốt hôm nay
                    _buildCalorieCard(),
                    const SizedBox(height: 24),

                    // Thẻ nước uống
                    _buildWaterCard(),
                    const SizedBox(height: 24),

                    // Banner dinh dưỡng
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NutritionScreen(),
                        ),
                      ).then((_) => _loadData()),
                      child: const WorkoutBanner(),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Phân tích tuần này'),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        );
                      },
                      child: const WeeklyAnalysisCard(),
                    ),
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

  Widget _buildWaterCard() {
    final double percent = (_todayWater / 2000.0).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WaterScreen()),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withAlpha(40),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THEO DÕI NƯỚC UỐNG',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã uống $_todayWater / 2000 ml',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đạt ${(percent * 100).toInt()}% mục tiêu hôm nay',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
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

// Deleted top-level _buildGoalCard

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
            // ElevatedButton(
            //   // onPressed: () => Navigator.push(
            //   //   context,
            //   //   MaterialPageRoute(builder: (_) => const NutritionScreen()),
            //   // ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFFDCE4FF),
            //     foregroundColor: const Color(0xFF0F75F4),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(20),
            //     ),
            //   ),
            //   child: const Text(
            //     'Xem dinh dưỡng',
            //     style: TextStyle(fontWeight: FontWeight.bold),
            //   ),
            // ),
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
