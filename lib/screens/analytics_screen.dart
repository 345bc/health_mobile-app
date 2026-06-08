import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/weekly_analysis_service.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final WeeklyAnalysisService _analysisService = WeeklyAnalysisService(
    ApiService(),
  );

  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  String _activeGoalType = 'STAY_HEALTHY';

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null || user.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Load active goal equivalent based on user BMI
      double bmi = 22.0;
      if (user.height != null && user.weight != null && user.height! > 0) {
        double h = user.height!;
        if (h > 10) {
          h = h / 100.0;
        }
        bmi = user.weight! / (h * h);
      }
      String goalType = 'STAY_HEALTHY';
      if (bmi > 24.9) {
        goalType = 'LOSE_WEIGHT';
      } else if (bmi < 18.5) {
        goalType = 'GAIN_MUSCLE';
      }

      // 3. Fetch weekly analysis from remote server
      final response = await _analysisService.getWeeklyAnalysis(user.userId!);
      if (response == null) {
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Không thể kết nối đến máy chủ.',
        );
      }
      Map<String, dynamic>? analysisData;
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data
            : {};
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          analysisData = data;
        }
      }

      setState(() {
        _activeGoalType = goalType;
        _analysisData = analysisData;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải báo cáo phân tích: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Không thể tải báo cáo phân tích từ máy chủ. Vui lòng kiểm tra lại kết nối mạng.",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final advices = _analysisData?['healthAdvices'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Thống kê tuần này',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F75F4)),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F75F4)),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              color: const Color(0xFF0F75F4),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SO SÁNH VỚI TUẦN TRƯỚC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C757D),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid of comparative cards
                    _buildComparisonsGrid(),
                    const SizedBox(height: 28),

                    // Advice Section
                    const Text(
                      'LỜI KHUYÊN SỨC KHỎE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C757D),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAdviceCard(advices),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildComparisonsGrid() {
    if (_analysisData == null) return const SizedBox.shrink();

    final steps = _analysisData!['steps'];
    final sleep = _analysisData!['sleepHours'];
    final calsBurned = _analysisData!['caloriesBurned'];
    final calsConsumed = _analysisData!['caloriesConsumed'];
    final heartRate = _analysisData!['averageHeartRate'];
    final weight = _analysisData!['averageWeight'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Bước chân',
                icon: Icons.directions_walk,
                color: const Color(0xFF0F75F4),
                comparison: steps,
                unit: ' bước',
                isHigherBetter: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Giờ ngủ',
                icon: Icons.nights_stay,
                color: const Color(0xFF8B5CF6),
                comparison: sleep,
                unit: ' giờ',
                isHigherBetter: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Calo tiêu thụ',
                icon: Icons.local_fire_department,
                color: const Color(0xFFF59E0B),
                comparison: calsBurned,
                unit: ' kcal',
                isHigherBetter: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Calo nạp vào',
                icon: Icons.restaurant,
                color: const Color(0xFF10B981),
                comparison: calsConsumed,
                unit: ' kcal',
                isHigherBetter: _activeGoalType == 'GAIN_MUSCLE',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Nhịp tim TB',
                icon: Icons.favorite,
                color: const Color(0xFFEF4444),
                comparison: heartRate,
                unit: ' bpm',
                isHigherBetter: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Cân nặng TB',
                icon: Icons.monitor_weight,
                color: const Color(0xFFEC4899),
                comparison: weight,
                unit: ' kg',
                isHigherBetter: _activeGoalType == 'GAIN_MUSCLE',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic>? comparison,
    required String unit,
    required bool isHigherBetter,
  }) {
    if (comparison == null) return const SizedBox.shrink();

    final double cur = (comparison['currentWeekValue'] as num).toDouble();
    final double prev = (comparison['previousWeekValue'] as num).toDouble();
    final double diff = (comparison['differencePercentage'] as num).toDouble();
    final bool isInc = comparison['isIncrease'] as bool? ?? false;

    // Check if the change direction is positive for health
    bool isHealthyChange = false;
    if (diff == 0.0) {
      isHealthyChange = true;
    } else {
      isHealthyChange = isHigherBetter ? isInc : !isInc;
    }

    final changeColor = isHealthyChange
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBECEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C757D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${cur.toStringAsFixed(cur == cur.toInt() ? 0 : 1)}$unit',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isInc ? Icons.arrow_upward : Icons.arrow_downward,
                color: changeColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${diff.abs()}% tuần trước (${prev.toStringAsFixed(prev == prev.toInt() ? 0 : 1)}$unit)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(List<dynamic> advices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F75F4), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F75F4).withAlpha(40),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Lời khuyên từ chuyên gia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...advices.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
