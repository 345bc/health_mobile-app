import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
  final WaterController _controller = WaterController();
  final DatabaseHelper _db = DatabaseHelper();
  int _todayTotal = 0;
  final int _targetWater = 2000;
  List<Map<String, dynamic>> _todayLogs = [];
  late AnimationController _waveController;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null || user.userId == null) {
      setState(() => _isLoading = false);

      return;
    }

    final userId = user.userId!;
    try {
      await _controller.refreshWaterLogsFromServer(userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Lỗi kết nối đến máy chủ. Hiển thị dữ liệu ngoại tuyến.",
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    try {
      final total = await _db.getTodayTotalWater(userId);
      final logs = await _db.getWaterLogsForDate(
        userId,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      setState(() {
        _todayTotal = total;
        _todayLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading water logs: $e");
      setState(() {
        _todayTotal = 0;
        _todayLogs = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addWater(int amount) async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null || user.userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _controller.logWater(
        userId: user.userId!,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        amount: amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận +$amount ml nước uống.'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lưu ngoại tuyến thành công."),
            backgroundColor: Colors.blueGrey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Reload
    final total = await _db.getTodayTotalWater(user.userId!);
    final logs = await _db.getWaterLogsForDate(
      user.userId!,
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    setState(() {
      _todayTotal = total;
      _todayLogs = logs;
      _isLoading = false;
    });
  }

  Future<void> _deleteLog(int id) async {
    setState(() => _isLoading = true);
    try {
      await _controller.deleteWaterLog(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xóa nhật ký nước uống thành công."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Đã xóa ngoại tuyến. Không thể kết nối với máy chủ để đồng bộ.",
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user != null && user.userId != null) {
      final total = await _db.getTodayTotalWater(user.userId!);
      final logs = await _db.getWaterLogsForDate(
        user.userId!,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      setState(() {
        _todayTotal = total;
        _todayLogs = logs;
      });
    }
    setState(() => _isLoading = false);
  }

  void _showCustomInput() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Nhập lượng nước tự chọn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập số ml nước (Ví dụ: 350)...',
            filled: true,
            fillColor: const Color(0xFFF0F6FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F75F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim()) ?? 0;
              if (val > 0) {
                Navigator.pop(ctx);
                _addWater(val);
              }
            },
            child: const Text(
              'Thêm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser();
    if (user == null || user.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Đang tải thông tin người dùng...')),
      );
    }

    final double progress = (_todayTotal / _targetWater).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Uống nước',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0284C7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Progress wave visualization card
                    _buildProgressCard(progress),
                    const SizedBox(height: 24),

                    // Quick add buttons
                    _buildQuickAddSection(),
                    const SizedBox(height: 24),

                    // Reminder configurations
                    AlarmReminderCard(userId: user.userId!, type: 'water'),
                    const SizedBox(height: 28),

                    // Today logs list card
                    _buildLogsCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress Background Track
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0F2FE),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withAlpha(15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Animated Liquid Circle
                  ClipPath(
                    clipper: _WaveClipper(_waveController.value, progress),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        ),
                      ),
                    ),
                  ),
                  // Progress text overlays
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_todayTotal',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: progress > 0.45
                              ? Colors.white
                              : const Color(0xFF0369A1),
                        ),
                      ),
                      Text(
                        '/ $_targetWater ml',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: progress > 0.55
                              ? Colors.white70
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _todayTotal >= _targetWater
                ? 'Hoàn thành mục tiêu uống nước! 🎉'
                : 'Đã đạt ${(progress * 100).toInt()}% chỉ tiêu hôm nay',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F75F4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THÊM NHANH NƯỚC UỐNG',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAddBtn(
                250,
                'Cốc nhỏ',
                Icons.local_drink_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAddBtn(
                500,
                'Chai vừa',
                Icons.local_drink_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _showCustomInput,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: Color(0xFF475569), size: 24),
                      SizedBox(height: 6),
                      Text(
                        'Tự chọn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAddBtn(int ml, String label, IconData icon) {
    return InkWell(
      onTap: () => _addWater(ml),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0284C7), size: 24),
            const SizedBox(height: 6),
            Text(
              '+$ml ml',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0369A1),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LỊCH SỬ HÔM NAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: _todayLogs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28.0),
                  child: Center(
                    child: Text(
                      'Chưa có ghi nhận nước uống nào hôm nay.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _todayLogs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Color(0xFFF1F5F9), height: 16),
                  itemBuilder: (context, index) {
                    final log = _todayLogs[index];
                    final int id = log['water_log_id'] ?? 0;
                    final int amount = log['amount'] ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0F2FE),
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Đã uống $amount ml',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteLog(id),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double progress;

  _WaveClipper(this.animationValue, this.progress);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double yOffset = size.height * (1.0 - progress);

    path.moveTo(0, yOffset);

    // Create wave curve
    if (progress > 0.0 && progress < 1.0) {
      for (double x = 0; x <= size.width; x++) {
        final double waveHeight = size.height * 0.04;
        // Note: Simple trigonometric function approximation
        final double rad =
            (animationValue * 2 * 3.141592) +
            (x / size.width * 2 * 3.141592 * 1.5);
        final double dynamicY =
            yOffset +
            (rad.hashCode.toDouble() % 5 - 2.5) +
            (waveHeight * 0.4) * (RadAngleSinCosApproximation.sin(rad));
        path.lineTo(x, dynamicY);
      }
    } else if (progress == 1.0) {
      path.lineTo(size.width, 0);
    } else {
      path.lineTo(size.width, size.height);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class RadAngleSinCosApproximation {
  static double sin(double radians) {
    // Simple Taylor series sin approximation
    double x = radians % (2 * 3.14159265);
    if (x < 0) x += 2 * 3.14159265;
    double term = x;
    double sum = x;
    double xSquared = x * x;
    double fact = 1.0;
    for (int i = 3; i <= 9; i += 2) {
      term = -term * xSquared;
      fact *= (i - 1) * i;
      sum += term / fact;
    }
    return sum;
  }
}
