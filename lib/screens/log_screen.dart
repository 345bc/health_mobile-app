import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/screens/nutrition_screen.dart';
import 'package:frontend/screens/vitals_screen.dart';
import 'package:frontend/data/controller/log_controller.dart';
import 'package:frontend/services/notification_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  DateTime _selectedDate = DateTime.now();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LogController _logController = LogController();

  String _weightText = '--';
  String _bloodPressureText = '--';
  String _mealsText = '--';
  String _moodText = '--';

  int _streakCount = 0;
  List<double> _weeklyCompletionRates = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLogs();
    });
  }

  Future<void> _initLogs() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user != null && user.userId != null) {
      try {
        await _logController.refreshLogsFromServer(user.userId!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Không thể đồng bộ dữ liệu từ máy chủ. Hiển thị dữ liệu ngoại tuyến (Offline).",
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    await _loadStatsForDate();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatsForDate() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser();
      if (user == null) return;
      final int userId = user.userId ?? 1;
      final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final db = await _dbHelper.database;

      // 1. Fetch body measurement for selected date
      final List<Map<String, dynamic>> measurements = await db.query(
        'body_measurements',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );

      String weightVal = 'Chưa ghi';
      String bpVal = 'Chưa ghi';
      if (measurements.isNotEmpty) {
        final m = measurements.first;
        if (m['weight'] != null) weightVal = '${m['weight']} KG';
        if (m['blood_pressure'] != null) bpVal = '${m['blood_pressure']} MMHG';
      }

      // 2. Fetch meals count for selected date
      final List<Map<String, dynamic>> meals = await db.query(
        'nutrition_logs',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );
      final int mealCount = meals.length;

      // 3. Fetch mood entry for selected date
      final List<Map<String, dynamic>> moods = await db.query(
        'mood_entries',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );
      String moodLabel = 'Chưa ghi';
      if (moods.isNotEmpty) {
        final int score = moods.first['mood_score'] ?? 3;
        if (score == 5) moodLabel = 'RẤT TỐT';
        if (score == 4) moodLabel = 'TỐT';
        if (score == 3) moodLabel = 'BÌNH THƯỜNG';
        if (score == 2) moodLabel = 'TỆ';
        if (score == 1) moodLabel = 'RẤT TỆ';
      }

      // 4. Calculate dynamic streak
      final int streak = await _logController.calculateStreak(userId);

      // 5. Calculate weekly completion
      final List<double> weeklyCompletion = await _logController
          .calculateWeeklyCompletion(userId);

      if (!mounted) return;

      setState(() {
        _weightText = weightVal;
        _bloodPressureText = bpVal;
        _mealsText = 'ĐÃ GHI $mealCount BỮA';
        _moodText = moodLabel;
        _streakCount = streak;
        _weeklyCompletionRates = weeklyCompletion;
      });
    } catch (e) {
      debugPrint("Error loading stats for date: $e");
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadStatsForDate();
    }
  }

  void _onTapCategory(String category) {
    if (category == 'Cân nặng') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VitalsScreen(initialTab: 0),
        ),
      ).then((_) => _loadStatsForDate());
    } else if (category == 'Huyết áp') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VitalsScreen(initialTab: 1),
        ),
      ).then((_) => _loadStatsForDate());
    } else if (category == 'Món ăn') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NutritionScreen()),
      ).then((_) => _loadStatsForDate());
    } else {
      _showLogDialog(category);
    }
  }

  void _showLogDialog(String category) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    final int userId = user?.userId ?? 1;
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (category == 'Cân nặng') {
      final controller = TextEditingController();
      bool isSaving = false;
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Ghi nhận Cân nặng'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 68.5',
                suffixText: 'KG',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final double? val = double.tryParse(controller.text);
                        if (val != null) {
                          setDialogState(() => isSaving = true);
                          try {
                            await _logController.logWeight(
                              userId: userId,
                              date: dateStr,
                              weight: val,
                            );
                            NotificationService().showNotification(
                              id: 30,
                              title: "Ghi nhận cân nặng",
                              body: "Đã lưu cân nặng $val KG thành công.",
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Ghi nhận cân nặng thành công! 🎉",
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Lưu ngoại tuyến thành công. Không thể kết nối với máy chủ để đồng bộ.",
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            _loadStatsForDate();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75F4),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else if (category == 'Huyết áp') {
      final controller = TextEditingController();
      bool isSaving = false;
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Ghi nhận Huyết áp'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 120/80',
                suffixText: 'mmHg',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final String val = controller.text.trim();
                        if (val.isNotEmpty) {
                          setDialogState(() => isSaving = true);
                          try {
                            await _logController.logBloodPressure(
                              userId: userId,
                              date: dateStr,
                              bloodPressure: val,
                            );
                            NotificationService().showNotification(
                              id: 31,
                              title: "Ghi nhận huyết áp",
                              body: "Đã lưu huyết áp $val mmHg thành công.",
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Ghi nhận huyết áp thành công! 🎉",
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Lưu ngoại tuyến thành công. Không thể kết nối với máy chủ để đồng bộ.",
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } finally {
                            _loadStatsForDate();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75F4),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else if (category == 'Tâm trạng') {
      double score = 4.0;
      final notesController = TextEditingController();
      bool isSaving = false;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Ghi nhận Tâm trạng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hôm nay bạn thấy thế nào?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: score,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  label: score == 5.0
                      ? 'Rất tốt'
                      : score == 4.0
                      ? 'Tốt'
                      : score == 3.0
                      ? 'Bình thường'
                      : score == 2.0
                      ? 'Tệ'
                      : 'Rất tệ',
                  onChanged: isSaving
                      ? null
                      : (val) {
                          setDialogState(() => score = val);
                        },
                ),
                Center(
                  child: Text(
                    score == 5.0
                        ? 'Rất tốt'
                        : score == 4.0
                        ? 'Tốt'
                        : score == 3.0
                        ? 'Bình thường'
                        : score == 2.0
                        ? 'Tệ'
                        : 'Rất tệ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F75F4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    hintText: 'Ghi chú thêm (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await _logController.logMood(
                            userId: userId,
                            date: dateStr,
                            moodScore: score.toInt(),
                            notes: notesController.text.trim(),
                          );
                          NotificationService().showNotification(
                            id: 32,
                            title: "Ghi nhận tâm trạng",
                            body: "Đã lưu trạng thái cảm xúc thành công.",
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Ghi nhận tâm trạng thành công! 🎉",
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Lưu ngoại tuyến thành công. Không thể kết nối với máy chủ để đồng bộ.",
                                ),
                                backgroundColor: Colors.blueGrey,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } finally {
                          try {
                            await _loadStatsForDate();
                          } catch (_) {}
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75F4),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
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
                    CategoryGrid(
                      weightText: _weightText,
                      bloodPressureText: _bloodPressureText,
                      mealsText: _mealsText,
                      moodText: _moodText,
                      onTapCategory: _onTapCategory,
                    ),

                    const SizedBox(height: 32),
                    ProgressCard(
                      ontap: () => _selectDate(),
                      streakCount: _streakCount,
                      weeklyCompletionRates: _weeklyCompletionRates,
                      selectedDate: _selectedDate,
                      onDaySelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadStatsForDate();
                      },
                    ),

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
  const LogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        SizedBox(width: 16),
      ],
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final String weightText;
  final String bloodPressureText;
  final String mealsText;
  final String moodText;
  final Function(String) onTapCategory;

  const CategoryGrid({
    super.key,
    required this.weightText,
    required this.bloodPressureText,
    required this.mealsText,
    required this.moodText,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onTapCategory('Cân nặng'),
                child: _buildCategoryCard(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: const Color(0xFF0F75F4),
                  title: 'Cân nặng',
                  subtitle: weightText.toUpperCase(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => onTapCategory('Huyết áp'),
                child: _buildCategoryCard(
                  icon: Icons.speed,
                  iconColor: const Color(0xFF198754),
                  title: 'Huyết áp',
                  subtitle: bloodPressureText.toUpperCase(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onTapCategory('Món ăn'),
                child: _buildCategoryCard(
                  icon: Icons.restaurant,
                  iconColor: const Color(0xFFD97706),
                  title: 'Món ăn',
                  subtitle: mealsText,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => onTapCategory('Tâm trạng'),
                child: _buildCategoryCard(
                  icon: Icons.sentiment_satisfied_alt,
                  iconColor: const Color(0xFFDC3545),
                  title: 'Tâm trạng',
                  subtitle: moodText,
                ),
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
            color: Colors.black.withAlpha(5),
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
  final int streakCount;
  final List<double> weeklyCompletionRates;
  final DateTime selectedDate;
  final void Function(DateTime)? onDaySelected;

  const ProgressCard({
    super.key,
    this.ontap,
    required this.streakCount,
    required this.weeklyCompletionRates,
    required this.selectedDate,
    this.onDaySelected,
  });

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
          Column(
            children: [
              Text(
                '$streakCount',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                  height: 1.0,
                ),
              ),
              const Text(
                'NGÀY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C757D),
                ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(
                'T2',
                weeklyCompletionRates.isNotEmpty
                    ? weeklyCompletionRates[0]
                    : 0.0,
                1,
              ),
              _buildBar(
                'T3',
                weeklyCompletionRates.length > 1
                    ? weeklyCompletionRates[1]
                    : 0.0,
                2,
              ),
              _buildBar(
                'T4',
                weeklyCompletionRates.length > 2
                    ? weeklyCompletionRates[2]
                    : 0.0,
                3,
              ),
              _buildBar(
                'T5',
                weeklyCompletionRates.length > 3
                    ? weeklyCompletionRates[3]
                    : 0.0,
                4,
              ),
              _buildBar(
                'T6',
                weeklyCompletionRates.length > 4
                    ? weeklyCompletionRates[4]
                    : 0.0,
                5,
              ),
              _buildBar(
                'T7',
                weeklyCompletionRates.length > 5
                    ? weeklyCompletionRates[5]
                    : 0.0,
                6,
              ),
              _buildBar(
                'CN',
                weeklyCompletionRates.length > 6
                    ? weeklyCompletionRates[6]
                    : 0.0,
                7,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTracker() {
    // Hiển thị ngày đang được chọn, không phải luôn hôm nay
    String formattedDate = DateFormat('EEE, d MMMM', 'vi').format(selectedDate);
    final bool isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFF0F2F5) : const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(30),
        border: isToday
            ? null
            : Border.all(color: const Color(0xFF0F75F4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              color: isToday
                  ? const Color(0xFF4A5568)
                  : const Color(0xFF0F75F4),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.calendar_month_outlined,
            color: isToday ? const Color(0xFF0F75F4) : const Color(0xFF0F75F4),
            size: 20,
          ),
        ],
      ),
    );
  }

  // Tính ngày trong tuần hiện tại (Thứ 2 - CN) từ weekday index
  DateTime _getDateForWeekday(int weekday) {
    final DateTime now = DateTime.now();
    final DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: weekday - 1));
  }

  Widget _buildBar(String label, double heightFactor, int weekday) {
    final DateTime barDate = _getDateForWeekday(weekday);
    final bool isSelected = DateUtils.isSameDay(selectedDate, barDate);
    final bool isToday = DateUtils.isSameDay(barDate, DateTime.now());
    final bool isFuture = barDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: isFuture ? null : () => onDaySelected?.call(barDate),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Dot indicator nếu là ngày được chọn
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF0F75F4) : Colors.transparent,
            ),
          ),
          Container(
            width: isFuture ? 8 : 10,
            height: (60 * heightFactor).clamp(4.0, 60.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0F75F4)
                  : isFuture
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFFAECBFA),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: (isSelected || isToday)
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF0F75F4)
                  : isFuture
                  ? const Color(0xFFBBBBBB)
                  : const Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }
}

class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF9D5B15),
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
              color: Colors.white.withAlpha(200),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

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
            colors: [Colors.transparent, Colors.white.withAlpha(200)],
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
