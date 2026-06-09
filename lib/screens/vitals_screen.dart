import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';

class VitalsScreen extends StatefulWidget {
  final int initialTab; // 0: Weight, 1: BP, 2: Glucose, 3: Heart Rate
  const VitalsScreen({super.key, this.initialTab = 0});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allMeasurements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      setState(() {}); // Refresh screen state to match tab index colors & titles
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
      final data = await ApiService.getBodyMeasurementsByUser(userId);
      final List<Map<String, dynamic>> normalized = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          normalized.add({
            'measurement_id': item['id'],
            'user_id': userId,
            'date': item['date'],
            'weight': item['weight'],
            'body_fat_percentage': item['bodyFatPercentage'],
            'blood_pressure': item['bloodPressure'],
            'blood_glucose': item['bloodGlucose'],
            'heart_rate': item['heartRate'],
          });
        }
      }
      if (mounted) {
        setState(() {
          _allMeasurements = normalized;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading body measurements: $e");
      if (mounted) {
        setState(() {
          _allMeasurements = [];
          _errorMessage = e.toString().replaceAll("Exception: ", "").trim();
          _isLoading = false;
        });
      }
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF0F75F4); // Weight - Blue
      case 1:
        return const Color(0xFF10B981); // Blood Pressure - Emerald
      case 2:
        return const Color(0xFFF59E0B); // Blood Glucose - Amber
      case 3:
        return const Color(0xFFEF4444); // Heart Rate - Red
      default:
        return const Color(0xFF0F75F4);
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Cân nặng';
      case 1:
        return 'Huyết áp';
      case 2:
        return 'Đường huyết';
      case 3:
        return 'Nhịp tim';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getTabColor(_tabController.index);
    final activeTitle = _getTabTitle(_tabController.index);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          activeTitle,
          style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: activeColor,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: activeColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Cân nặng'),
            Tab(text: 'Huyết áp'),
            Tab(text: 'Đường huyết'),
            Tab(text: 'Nhịp tim'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(_tabController.index),
        backgroundColor: activeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm số đo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(0),
                    _buildTabContent(1),
                    _buildTabContent(2),
                    _buildTabContent(3),
                  ],
                ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    // Filter records specific to this vital type
    List<Map<String, dynamic>> filteredList = [];
    for (var m in _allMeasurements) {
      if (tabIndex == 0 && m['weight'] != null) filteredList.add(m);
      if (tabIndex == 1 && m['blood_pressure'] != null) filteredList.add(m);
      if (tabIndex == 2 && m['blood_glucose'] != null) filteredList.add(m);
      if (tabIndex == 3 && m['heart_rate'] != null) filteredList.add(m);
    }

    // Sort ascending for chart (chronological)
    List<Map<String, dynamic>> chartData = List.from(filteredList);
    chartData.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    if (chartData.length > 8) {
      chartData = chartData.sublist(chartData.length - 8);
    }

    // Sort descending for history list (newest first)
    List<Map<String, dynamic>> listData = List.from(filteredList);
    listData.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    final themeColor = _getTabColor(tabIndex);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: themeColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Chart Card
            _buildChartCard(tabIndex, chartData, themeColor),
            const SizedBox(height: 28),

            // Section 2: Recent Logs Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LỊCH SỬ GHI CHÉP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${filteredList.length} bản ghi',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Section 3: Logs List
            if (listData.isEmpty)
              _buildEmptyState(tabIndex)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listData.length,
                itemBuilder: (context, index) {
                  final item = listData[index];
                  return _buildLogItem(tabIndex, item, themeColor);
                },
              ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final user = Provider.of<UserProvider>(context, listen: false).getUser();
                if (user != null) {
                  final int userId = user['id'] ?? user['userId'] ?? 0;
                  return AlarmReminderCard(userId: userId, type: 'vitals');
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(int tabIndex, List<Map<String, dynamic>> chartData, Color themeColor) {
    if (chartData.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEBECEE)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Chưa đủ dữ liệu để vẽ biểu đồ xu hướng',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBECEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'XU HƯỚNG GẦN ĐÂY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              _getChartData(tabIndex, chartData, themeColor),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _getChartData(int tabIndex, List<Map<String, dynamic>> chartData, Color themeColor) {
    List<FlSpot> spots1 = [];
    List<FlSpot> spots2 = []; // Used for blood pressure (systolic and diastolic)

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      if (tabIndex == 0) {
        spots1.add(FlSpot(i.toDouble(), (item['weight'] as num).toDouble()));
      } else if (tabIndex == 1) {
        // Parse "120/80" -> systolic 120, diastolic 80
        final bpStr = item['blood_pressure'] as String? ?? '120/80';
        final parts = bpStr.split('/');
        final double sys = parts.isNotEmpty ? (double.tryParse(parts[0]) ?? 120.0) : 120.0;
        final double dia = parts.length > 1 ? (double.tryParse(parts[1]) ?? 80.0) : 80.0;
        spots1.add(FlSpot(i.toDouble(), sys));
        spots2.add(FlSpot(i.toDouble(), dia));
      } else if (tabIndex == 2) {
        spots1.add(FlSpot(i.toDouble(), (item['blood_glucose'] as num).toDouble()));
      } else if (tabIndex == 3) {
        spots1.add(FlSpot(i.toDouble(), (item['heart_rate'] as num).toDouble()));
      }
    }

    final List<LineChartBarData> lineBars = [];

    if (tabIndex == 1) {
      // Blood Pressure draws two lines
      lineBars.add(
        LineChartBarData(
          spots: spots1,
          isCurved: true,
          color: const Color(0xFFEF4444), // Systolic Red
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFFEF4444).withAlpha(20),
          ),
        ),
      );
      lineBars.add(
        LineChartBarData(
          spots: spots2,
          isCurved: true,
          color: const Color(0xFF3B82F6), // Diastolic Blue
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF3B82F6).withAlpha(20),
          ),
        ),
      );
    } else {
      lineBars.add(
        LineChartBarData(
          spots: spots1,
          isCurved: true,
          color: themeColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: themeColor.withAlpha(30),
          ),
        ),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade100,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              int idx = value.toInt();
              if (idx >= 0 && idx < chartData.length) {
                final dateStr = chartData[idx]['date'] as String;
                try {
                  final dt = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('dd/MM').format(dt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                } catch (_) {}
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      lineBarsData: lineBars,
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    IconData icon = Icons.monitor_weight;
    if (tabIndex == 1) icon = Icons.speed;
    if (tabIndex == 2) icon = Icons.bloodtype;
    if (tabIndex == 3) icon = Icons.favorite;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử đo cho mục này.\nNhấn nút bên dưới để thêm mới!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(int tabIndex, Map<String, dynamic> item, Color themeColor) {
    final DateTime dt = DateTime.parse(item['date']);
    final dateFormatted = DateFormat('EEE, d MMM yyyy').format(dt);

    String valueText = '';
    String unitText = '';
    IconData leadingIcon = Icons.show_chart;

    if (tabIndex == 0) {
      valueText = '${item['weight']}';
      unitText = ' kg';
      leadingIcon = Icons.monitor_weight_outlined;
    } else if (tabIndex == 1) {
      valueText = '${item['blood_pressure']}';
      unitText = ' mmHg';
      leadingIcon = Icons.speed;
    } else if (tabIndex == 2) {
      valueText = '${item['blood_glucose']}';
      unitText = ' mmol/L';
      leadingIcon = Icons.bloodtype_outlined;
    } else if (tabIndex == 3) {
      valueText = '${item['heart_rate']}';
      unitText = ' bpm';
      leadingIcon = Icons.favorite_border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: themeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(leadingIcon, color: themeColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatted,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111111), fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Số đo',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: valueText,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                    TextSpan(
                      text: unitText,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(item['measurement_id']),
          )
        ],
      ),
    );
  }

  void _confirmDelete(int? id) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa số đo sinh hiệu'),
        content: const Text('Bạn có chắc chắn muốn xóa bản ghi đo lường sinh hiệu này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteBodyMeasurement(id);
        NotificationService().showNotification(
          id: 35,
          title: "Xóa thành công",
          body: "Bản ghi đo lường sinh hiệu đã được xóa khỏi hệ thống.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xóa bản ghi sinh hiệu thành công."),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi: ${e.toString().replaceAll("Exception: ", "").trim()}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        _loadData();
      }
    }
  }

  void _showAddDialog(int tabIndex) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    final int userId = user?['id'] ?? user?['userId'] ?? 1;

    final controller1 = TextEditingController();
    final controller2 = TextEditingController(); // For Systolic/Diastolic BP

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Thêm số đo ${_getTabTitle(tabIndex)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: Color(0xFF0F75F4)),
                  title: Text(
                    'Ngày ghi: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Inputs specific to tab vital type
                if (tabIndex == 0)
                  TextField(
                    controller: controller1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng',
                      suffixText: 'KG',
                      border: OutlineInputBorder(),
                    ),
                  )
                else if (tabIndex == 1) ...[
                  TextField(
                    controller: controller1,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tâm thu (Systolic)',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller2,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tâm trương (Diastolic)',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (tabIndex == 2)
                  TextField(
                    controller: controller1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Chỉ số đường huyết',
                      suffixText: 'mmol/L',
                      border: OutlineInputBorder(),
                    ),
                  )
                else if (tabIndex == 3)
                  TextField(
                    controller: controller1,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nhịp tim',
                      suffixText: 'BPM',
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  // Gọi GET để kiểm tra xem đã có bản ghi nào trong ngày dateStr chưa
                  final measurements = await ApiService.getBodyMeasurementsByUser(userId);
                  Map<String, dynamic>? existing;
                  for (var m in measurements) {
                    if (m is Map<String, dynamic> && m['date'] == dateStr) {
                      existing = m;
                      break;
                    }
                  }

                  // Chuẩn bị data update hoặc create
                  final Map<String, dynamic> measurementData = {
                    'userId': userId,
                    'date': dateStr,
                  };

                  if (existing != null) {
                    measurementData['weight'] = existing['weight'];
                    measurementData['bloodPressure'] = existing['bloodPressure'];
                    measurementData['heartRate'] = existing['heartRate'];
                    measurementData['bodyFatPercentage'] = existing['bodyFatPercentage'];
                    measurementData['bloodGlucose'] = existing['bloodGlucose'];
                  }

                  if (tabIndex == 0) {
                    final val = double.tryParse(controller1.text);
                    if (val != null) {
                      measurementData['weight'] = val;
                      if (existing != null) {
                        await ApiService.updateBodyMeasurement(existing['id'], measurementData);
                      } else {
                        await ApiService.createBodyMeasurement(measurementData);
                      }
                      NotificationService().showNotification(
                        id: 30,
                        title: "Ghi nhận cân nặng",
                        body: "Đã lưu cân nặng $val KG thành công.",
                      );
                    }
                  } else if (tabIndex == 1) {
                    final sys = int.tryParse(controller1.text);
                    final dia = int.tryParse(controller2.text);
                    if (sys != null && dia != null) {
                      final bpText = '$sys/$dia';
                      measurementData['bloodPressure'] = bpText;
                      if (existing != null) {
                        await ApiService.updateBodyMeasurement(existing['id'], measurementData);
                      } else {
                        await ApiService.createBodyMeasurement(measurementData);
                      }
                      NotificationService().showNotification(
                        id: 31,
                        title: "Ghi nhận huyết áp",
                        body: "Đã lưu huyết áp $bpText mmHg thành công.",
                      );
                    }
                  } else if (tabIndex == 2) {
                    final val = double.tryParse(controller1.text);
                    if (val != null) {
                      measurementData['bloodGlucose'] = val;
                      if (existing != null) {
                        await ApiService.updateBodyMeasurement(existing['id'], measurementData);
                      } else {
                        await ApiService.createBodyMeasurement(measurementData);
                      }
                      NotificationService().showNotification(
                        id: 32,
                        title: "Ghi nhận đường huyết",
                        body: "Đã lưu chỉ số đường huyết $val mmol/L thành công.",
                      );
                    }
                  } else if (tabIndex == 3) {
                    final val = int.tryParse(controller1.text);
                    if (val != null) {
                      measurementData['heartRate'] = val;
                      if (existing != null) {
                        await ApiService.updateBodyMeasurement(existing['id'], measurementData);
                      } else {
                        await ApiService.createBodyMeasurement(measurementData);
                      }
                      NotificationService().showNotification(
                        id: 33,
                        title: "Ghi nhận nhịp tim",
                        body: "Đã lưu nhịp tim $val BPM thành công.",
                      );
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ghi nhận số đo sinh hiệu thành công! 🎉"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lỗi: ${e.toString().replaceAll("Exception: ", "").trim()}"),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _getTabColor(tabIndex)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
