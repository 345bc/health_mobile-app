import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/controller/sleep_controller.dart';
import 'package:frontend/data/models/sleep_log.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final SleepController _ctrl = SleepController();

  SleepLog? _lastSleep;
  List<SleepLog> _recentSleeps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) { setState(() => _isLoading = false); return; }
    final int uid = user.userId!;

    try {
      final results = await Future.wait([
        _ctrl.getLastSleep(uid),
        _ctrl.getRecentSleeps(uid, days: 7),
      ]);

      if (!mounted) return;
      setState(() {
        _lastSleep = results[0] as SleepLog?;
        _recentSleeps = results[1] as List<SleepLog>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading sleep data: $e");
      if (mounted) {
        setState(() {
          _lastSleep = null;
          _recentSleeps = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showLogDialog() async {
    DateTime selectedLogDate = DateTime.now();
    TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 30);
    TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);
    int qualityScore = 4;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ghi nhận giấc ngủ'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Chọn ngày
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
                    setDialogState(() => selectedLogDate = picked);
                  }
                },
              ),
              // Giờ ngủ
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bedtime, color: Color(0xFF0F75F4)),
                title: const Text('Giờ ngủ'),
                trailing: Text(bedTime.format(ctx),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final t = await showTimePicker(
                      context: ctx, initialTime: bedTime);
                  if (t != null) setDialogState(() => bedTime = t);
                },
              ),
              // Giờ thức
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text('Giờ thức'),
                trailing: Text(wakeTime.format(ctx),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final t = await showTimePicker(
                      context: ctx, initialTime: wakeTime);
                  if (t != null) setDialogState(() => wakeTime = t);
                },
              ),
              const SizedBox(height: 8),
              // Chất lượng
              Row(children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Text('Chất lượng: '),
                Expanded(
                  child: Slider(
                    value: qualityScore.toDouble(),
                    min: 1, max: 5, divisions: 4,
                    label: _qualityLabel(qualityScore),
                    onChanged: (v) =>
                        setDialogState(() => qualityScore = v.toInt()),
                  ),
                ),
              ]),
              Text(_qualityLabel(qualityScore),
                  style: const TextStyle(
                      color: Color(0xFF0F75F4), fontWeight: FontWeight.bold)),
            ]),
          ),
          actions: [
            Builder(builder: (context) {
              bool isSaving = false;
              return StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                                final user = Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                ).getUser();
                                if (user == null) return;
                                final date =
                                    DateFormat('yyyy-MM-dd').format(selectedLogDate);
                                final startStr =
                                    '${bedTime.hour.toString().padLeft(2, '0')}:${bedTime.minute.toString().padLeft(2, '0')}';
                                final endStr =
                                    '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}';

                                setDialogState(() => isSaving = true);
                                try {
                                  await _ctrl.logSleep(
                                    userId: user.userId!,
                                    date: date,
                                    startTime: startStr,
                                    endTime: endStr,
                                    qualityScore: qualityScore,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _load();
                                } catch (e) {
                                  setDialogState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Lỗi kết nối tới máy chủ. Giấc ngủ đã được lưu ngoại tuyến.'),
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
                            : const Text('Lưu',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(int score) {
    switch (score) {
      case 5: return 'Rất tốt';
      case 4: return 'Tốt';
      case 3: return 'Bình thường';
      case 2: return 'Tệ';
      default: return 'Rất tệ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Giấc ngủ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogDialog,
        backgroundColor: const Color(0xFF5B3D8D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ghi giấc ngủ',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B3D8D)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildLastSleepCard(),
                  const SizedBox(height: 24),
                  const Text('LỊCH SỬ 7 NGÀY',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C757D),
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  if (_recentSleeps.isEmpty)
                    _emptyState()
                  else
                    ..._recentSleeps.map(_buildSleepItem),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final user = Provider.of<UserProvider>(context, listen: false).getUser();
                      if (user != null && user.userId != null) {
                        return AlarmReminderCard(userId: user.userId!, type: 'sleep');
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

  Widget _buildLastSleepCard() {
    final sleep = _lastSleep;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1A78), Color(0xFF7B52C8)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GIẤC NGỦ GẦN NHẤT',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text(
          sleep?.durationFormatted ?? '--',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1),
        ),
        if (sleep != null) ...[
          const SizedBox(height: 8),
          Text('${sleep.startTime} → ${sleep.endTime}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(_qualityLabel(sleep.qualityScore ?? 3),
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
        ] else
          const Text('Chưa có dữ liệu. Nhấn + để ghi.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSleepItem(SleepLog s) {
    final date = DateFormat('EEE, d MMM').format(DateTime.parse(s.date));
    final qualityColor = (s.qualityScore ?? 3) >= 4
        ? Colors.green
        : (s.qualityScore ?? 3) >= 3
            ? Colors.orange
            : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBECEE)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFF0E8FF),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bedtime, color: Color(0xFF5B3D8D), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF111111))),
            Text('${s.startTime} → ${s.endTime}',
                style: const TextStyle(
                    color: Color(0xFF6C757D), fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s.durationFormatted,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B3D8D))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: qualityColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_qualityLabel(s.qualityScore ?? 3),
                style: TextStyle(
                    color: qualityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có dữ liệu giấc ngủ.\nNhấn + để ghi nhận!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ]),
        ),
      );
}
