import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/controller/activity_controller.dart';
import 'package:frontend/data/models/activity.dart';
import 'package:intl/intl.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';
import 'package:frontend/services/token_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityController _ctrl = ActivityController();

  Activity? _todayActivity;
  List<Activity> _recentActivities = [];
  bool _isLoading = true;
  int _targetSteps = 10000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);
      final user = Provider.of<UserProvider>(context, listen: false).getUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final int uid = user.userId!;

      final results = await Future.wait([
        _ctrl.getTodayActivity(uid),
        _ctrl.getRecentActivities(uid, days: 7),
        tokenService().getTargetSteps(),
      ]);

      if (!mounted) return;

      setState(() {
        _todayActivity = results[0] as Activity?;
        _recentActivities = results[1] as List<Activity>;
        _targetSteps = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu hoạt động: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTargetStepsDialog() async {
    final ctrl = TextEditingController(text: _targetSteps.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đặt mục tiêu bước chân'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: 10000',
            suffixText: 'bước',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F75F4),
            ),
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim()) ?? 10000;
              if (val > 0) {
                await tokenService().saveTargetSteps(val);
                setState(() {
                  _targetSteps = val;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogDialog() async {
    DateTime selectedLogDate = DateTime.now();
    final stepsCtrl = TextEditingController();
    final distanceCtrl = TextEditingController();

    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) return;
    final int uid = user.userId!;

    Future<void> loadActivityForDate(DateTime date, Function setDialogState) async {
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);
      final existing = await _ctrl.getActivityForDate(uid, dateStr);
      setDialogState(() {
        stepsCtrl.text = existing?.steps.toString() ?? '';
        distanceCtrl.text = existing?.distance.toString() ?? '';
      });
    }

    double weight = 60.0;
    if (user.weight != null && user.weight! > 0) {
      weight = user.weight!;
    } else {
      final latest = await DatabaseHelper().getLatestBodyMeasurement(uid);
      if (latest != null && latest['weight'] != null) {
        weight = (latest['weight'] as num).toDouble();
      }
    }

    if (!mounted) return;

    bool isSaving = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (stepsCtrl.text.isEmpty && distanceCtrl.text.isEmpty && !isSaving) {
            loadActivityForDate(selectedLogDate, setDialogState);
          }

          final double distanceVal = double.tryParse(distanceCtrl.text) ?? 
              ((int.tryParse(stepsCtrl.text) ?? 0) * 0.00075);
          final int calculatedCalories = (weight * distanceVal * 0.75).round();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Ghi nhận vận động'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF0F75F4)),
                    title: const Text('Ngày ghi nhận'),
                    trailing: Text(
                      DateFormat('dd/MM/yyyy').format(selectedLogDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedLogDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedLogDate = picked;
                          stepsCtrl.clear();
                          distanceCtrl.clear();
                        });
                        await loadActivityForDate(picked, setDialogState);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    stepsCtrl,
                    'Số bước chân',
                    'bước',
                    TextInputType.number,
                    onChanged: (val) {
                      final steps = int.tryParse(val) ?? 0;
                      final dist = steps * 0.00075;
                      setDialogState(() {
                        distanceCtrl.text = dist > 0 ? dist.toStringAsFixed(2) : '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    distanceCtrl,
                    'Quãng đường',
                    'km',
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEBECEE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calo tiêu hao tự động:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057)),
                        ),
                        Text(
                          '$calculatedCalories kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF0F75F4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75F4),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final int steps = int.tryParse(stepsCtrl.text) ?? 0;
                        double distance = double.tryParse(distanceCtrl.text) ?? 0.0;
                        if (distance == 0 && steps > 0) {
                          distance = steps * 0.00075;
                        }

                        final int calories = (weight * distance * 0.75).round();

                        setDialogState(() => isSaving = true);
                        try {
                          final String dateStr = DateFormat('yyyy-MM-dd').format(selectedLogDate);
                          await _ctrl.upsertTodayActivity(
                            userId: uid,
                            steps: steps,
                            distance: distance,
                            caloriesBurned: calories,
                            date: dateStr,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Lỗi kết nối tới máy chủ. Dữ liệu đã được lưu ngoại tuyến.'),
                                backgroundColor: Colors.amber[800],
                              ),
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        }
                      },
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Vận động',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_road),
            tooltip: 'Đặt mục tiêu bước chân',
            onPressed: _showTargetStepsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogDialog,
        backgroundColor: const Color(0xFF0F75F4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ghi vận động',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildTodayCard(),
                  const SizedBox(height: 24),
                  const Text(
                    '7 NGÀY GẦN NHẤT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C757D),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recentActivities.isEmpty)
                    _emptyState(
                      'Chưa có dữ liệu vận động.\nNhấn "Ghi hôm nay" để bắt đầu!',
                    )
                  else
                    ..._recentActivities.map(_buildActivityItem),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final user = Provider.of<UserProvider>(context, listen: false).getUser();
                      if (user != null && user.userId != null) {
                        return AlarmReminderCard(userId: user.userId!, type: 'activity');
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildTodayCard() {
    final int steps = _todayActivity?.steps ?? 0;
    final int cal = _todayActivity?.caloriesBurned ?? 0;
    final double dist = _todayActivity?.distance ?? 0;
    final int target = _targetSteps;
    final double progress = (steps / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F75F4), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F75F4).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HÔM NAY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$steps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bước',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'chân',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% mục tiêu $target bước',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip(Icons.local_fire_department, '$cal kcal'),
              const SizedBox(width: 12),
              _statChip(Icons.straighten, '${dist.toStringAsFixed(1)} km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(30),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _buildActivityItem(Activity a) {
    final date = DateFormat('EEE, d MMM').format(DateTime.parse(a.date));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBECEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_walk,
              color: Color(0xFF0F75F4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                Text(
                  '${a.caloriesBurned} kcal  •  ${a.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Color(0xFF6C757D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${a.steps}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F75F4),
            ),
          ),
          const Text(
            ' bước',
            style: TextStyle(color: Color(0xFF6C757D), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.directions_walk, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    String suffix,
    TextInputType type, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
