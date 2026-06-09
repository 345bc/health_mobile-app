import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';
import 'package:frontend/services/api_service.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  Map<String, dynamic>? _lastSleep;
  List<dynamic> _recentSleeps = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
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
      final sleeps = await ApiService.getSleepsByUser(userId);

      Map<String, dynamic>? lastSleep;
      if (sleeps.isNotEmpty) {
        final sortedSleeps = List.from(sleeps);
        sortedSleeps.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
        lastSleep = sortedSleeps.first;
      }

      if (!mounted) return;
      setState(() {
        _lastSleep = lastSleep;
        _recentSleeps = sleeps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading sleep data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "").trim();
          _isLoading = false;
        });
      }
    }
  }

  void _showLogDialog() {
    DateTime selectedLogDate = DateTime.now();
    TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 30);
    TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);
    int qualityScore = 3;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.bedtime, color: Color(0xFF5B3D8D)),
                  SizedBox(width: 8),
                  Text('Ghi nhận giấc ngủ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Ngày ngủ'),
                      trailing: Text(
                          DateFormat('yyyy-MM-dd').format(selectedLogDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedLogDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedLogDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.airline_seat_flat),
                      title: const Text('Giờ đi ngủ'),
                      trailing: Text(bedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: bedTime);
                        if (picked != null) {
                          setDialogState(() => bedTime = picked);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: const Text('Giờ thức dậy'),
                      trailing: Text(wakeTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: wakeTime);
                        if (picked != null) {
                          setDialogState(() => wakeTime = picked);
                        }
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chất lượng giấc ngủ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final val = index + 1;
                        return GestureDetector(
                          onTap: () => setDialogState(() => qualityScore = val),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: qualityScore == val
                                  ? const Color(0xFF5B3D8D)
                                  : Colors.grey.shade100,
                            ),
                            child: Text(
                              '$val',
                              style: TextStyle(
                                  color: qualityScore == val
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(_qualityLabel(qualityScore),
                        style: const TextStyle(
                            color: Color(0xFF5B3D8D),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: const Text('Hủy',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3D8D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final user = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).getUser();
                          if (user == null) return;
                          final int userId = user['id'] ?? user['userId'] ?? 0;
                          final date = DateFormat('yyyy-MM-dd').format(selectedLogDate);
                          final startStr =
                              '${bedTime.hour.toString().padLeft(2, '0')}:${bedTime.minute.toString().padLeft(2, '0')}';
                          final endStr =
                              '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}';

                          setDialogState(() => isSaving = true);
                          try {
                            await ApiService.createSleep({
                              'userId': userId,
                              'date': date,
                              'startTime': startStr,
                              'endTime': endStr,
                              'qualityScore': qualityScore,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "").trim()}'),
                                  backgroundColor: Colors.redAccent,
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
      },
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

  String _formatDuration(int? durationMinutes) {
    if (durationMinutes == null) return '--';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5B3D8D)),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogDialog,
        backgroundColor: const Color(0xFF5B3D8D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ghi giấc ngủ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B3D8D)))
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
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B3D8D),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
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
                          final int? userId = user?['id'] ?? user?['userId'];
                          if (userId != null) {
                            return AlarmReminderCard(userId: userId, type: 'sleep');
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
    final int? dur = sleep != null ? (sleep['duration'] ?? sleep['duration_minutes']) : null;
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
          _formatDuration(dur),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1),
        ),
        if (sleep != null) ...[
          const SizedBox(height: 8),
          Text('${sleep['startTime'] ?? sleep['start_time'] ?? ''} → ${sleep['endTime'] ?? sleep['end_time'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(_qualityLabel(sleep['qualityScore'] ?? sleep['quality_score'] ?? 3),
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
        ] else
          const Text('Chưa có dữ liệu. Nhấn + để ghi.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSleepItem(dynamic s) {
    final dateStr = s['date']?.toString() ?? '';
    final date = dateStr.isNotEmpty ? DateFormat('EEE, d MMM').format(DateTime.parse(dateStr)) : '--';
    final int score = s['qualityScore'] ?? s['quality_score'] ?? 3;
    final int? dur = s['duration'] ?? s['duration_minutes'];
    final qualityColor = score >= 4
        ? Colors.green
        : score >= 3
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
            Text('${s['startTime'] ?? s['start_time'] ?? ''} → ${s['endTime'] ?? s['end_time'] ?? ''}',
                style: const TextStyle(
                    color: Color(0xFF6C757D), fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatDuration(dur),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B3D8D))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: qualityColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_qualityLabel(score),
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
