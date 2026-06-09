import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';
import 'package:frontend/services/token_service.dart';
import 'package:frontend/services/api_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Map<String, dynamic>? _todayActivity;
  List<dynamic> _recentActivities = [];
  bool _isLoading = true;
  int _targetSteps = 10000;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final user = Provider.of<UserProvider>(context, listen: false).getUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final int uid = user['id'] ?? user['userId'] ?? 0;

      final results = await Future.wait([
        ApiService.getActivitiesByUser(uid),
        tokenService().getTargetSteps(),
      ]);

      if (!mounted) return;

      final List<dynamic> activities = results[0] as List<dynamic>;
      final int targetSteps = results[1] as int;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic>? todayActivity;
      for (var act in activities) {
        if (act['date'] == todayStr) {
          todayActivity = act;
          break;
        }
      }

      setState(() {
        _todayActivity = todayActivity;
        _recentActivities = activities;
        _targetSteps = targetSteps;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "").trim();
          _isLoading = false;
        });
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
    final int uid = user['id'] ?? user['userId'] ?? 0;

    Future<void> loadActivityForDate(DateTime date, Function setDialogState) async {
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);
      try {
        final allActivities = await ApiService.getActivitiesByUser(uid);
        Map<String, dynamic>? existing;
        for (var a in allActivities) {
          if (a['date'] == dateStr) {
            existing = a;
            break;
          }
        }
        setDialogState(() {
          stepsCtrl.text = existing?['steps']?.toString() ?? '';
          distanceCtrl.text = existing?['distance']?.toString() ?? '';
        });
      } catch (_) {}
    }

    double weight = 60.0;
    final endUser = user['endUser'];
    if (endUser != null && endUser['weight'] != null) {
      weight = (endUser['weight'] as num).toDouble();
    } else {
      try {
        final measurements = await ApiService.getBodyMeasurementsByUser(uid);
        if (measurements.isNotEmpty) {
          final sortedMeasurements = List.from(measurements);
          sortedMeasurements.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
          final latest = sortedMeasurements.first;
          if (latest['weight'] != null) {
            weight = (latest['weight'] as num).toDouble();
          }
        }
      } catch (_) {}
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
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedLogDate = picked;
                          stepsCtrl.clear();
                          distanceCtrl.clear();
                        });
                        loadActivityForDate(picked, setDialogState);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stepsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số bước chân',
                      prefixIcon: Icon(Icons.directions_run),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: distanceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Khoảng cách (km)',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Calo tiêu thụ dự tính:'),
                        Text(
                          '$calculatedCalories kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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
                          
                          final allActivities = await ApiService.getActivitiesByUser(uid);
                          Map<String, dynamic>? existing;
                          for (var a in allActivities) {
                            if (a['date'] == dateStr) {
                              existing = a;
                              break;
                            }
                          }

                          final Map<String, dynamic> data = {
                            'userId': uid,
                            'steps': steps,
                            'distance': distance,
                            'caloriesBurned': calories,
                            'date': dateStr,
                          };

                          if (existing != null) {
                            final int activityId = existing['id'] ?? existing['activityId'] ?? 0;
                            await ApiService.updateActivity(activityId, data);
                          } else {
                            await ApiService.createActivity(data);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "").trim()}'),
                                backgroundColor: Colors.red,
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
        title: const Text('Vận động', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F75F4)),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogDialog,
        backgroundColor: const Color(0xFF0F75F4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ghi vận động',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F75F4)))
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
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTodayCard(),
                      const SizedBox(height: 24),
                      const Text('LỊCH SỬ 7 NGÀY',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C757D),
                              letterSpacing: 1)),
                      const SizedBox(height: 12),
                      if (_recentActivities.isEmpty)
                        _emptyState()
                      else
                        ..._recentActivities.map(_buildActivityItem),
                      const SizedBox(height: 24),
                      Builder(
                        builder: (context) {
                          final user = Provider.of<UserProvider>(context, listen: false).getUser();
                          final int? userId = user?['id'] ?? user?['userId'];
                          if (userId != null) {
                            return AlarmReminderCard(userId: userId, type: 'activity');
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
    final int steps = _todayActivity?['steps'] ?? 0;
    final int cal = _todayActivity?['caloriesBurned'] ?? _todayActivity?['calories_burned'] ?? 0;
    final double dist = _todayActivity?['distance'] != null ? (_todayActivity!['distance'] as num).toDouble() : 0.0;
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    'Mục tiêu: $target bước',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _showTargetStepsDialog,
              )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _todayStatItem(Icons.local_fire_department, '$cal kcal', 'Calo tiêu thụ'),
              Container(width: 1, height: 24, color: Colors.white24),
              _todayStatItem(Icons.map_outlined, '${dist.toStringAsFixed(2)} km', 'Quãng đường'),
            ],
          )
        ],
      ),
    );
  }

  Widget _todayStatItem(IconData icon, String val, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            )
          ],
        )
      ],
    );
  }

  Widget _buildActivityItem(dynamic a) {
    final String dateStr = a['date']?.toString() ?? '';
    final date = dateStr.isNotEmpty ? DateFormat('EEE, d MMM').format(DateTime.parse(dateStr)) : '--';
    final int steps = a['steps'] ?? 0;
    final int cal = a['caloriesBurned'] ?? a['calories_burned'] ?? 0;
    final double dist = a['distance'] != null ? (a['distance'] as num).toDouble() : 0.0;

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
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_run, color: Color(0xFF0F75F4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111111)),
                ),
                Text(
                  '$cal kcal  •  ${dist.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$steps bước',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.directions_run, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu vận động.\nNhấn + để ghi nhận!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
