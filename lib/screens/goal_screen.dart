import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/goal_service.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/data/database_helper.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final GoalService _goalService = GoalService(ApiService());
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  Map<String, dynamic>? _activeGoal;
  Map<String, dynamic>? _recommendations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoalData());
  }

  Map<String, dynamic> _normalizeGoal(Map<String, dynamic> dbGoal) {
    return {
      'id': dbGoal['goal_id'],
      'userId': dbGoal['user_id'],
      'goalType': dbGoal['goal_type'],
      'targetValue': dbGoal['target_value'],
      'startDate': dbGoal['start_date'],
      'endDate': dbGoal['end_date'],
      'status': dbGoal['status'],
    };
  }

  // ── BMI helpers ────────────────────────────────────────────────────────────
  double? _calcBmi(User? user) {
    if (user == null) return null;
    final w = user.weight;
    var h = user.height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    if (h > 3) h = h / 100; // cm → m
    return w / (h * h);
  }

  int _calcAge(User? user) {
    if (user?.dateOfBirth == null) return 30;
    try {
      final dob = DateTime.parse(user!.dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 30;
    }
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25.0) return 'Bình thường';
    if (bmi < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFFF59E0B);
    if (bmi < 25.0) return const Color(0xFF10B981);
    if (bmi < 30.0) return const Color(0xFFFF6B35);
    return const Color(0xFFEF4444);
  }

  // ── Personalized local recommendations ─────────────────────────────────────
  Map<String, dynamic> _getLocalRecommendations(String goalType, User? user) {
    final bmi = _calcBmi(user);
    final age = _calcAge(user);
    final bool isOverweight = bmi != null && bmi >= 25.0;
    final bool isObese = bmi != null && bmi >= 30.0;
    final bool isSenior = age >= 55;

    // Default diet targets
    int targetCal = 2000;
    double targetProtein = 125;
    double targetCarbs = 250;
    double targetFat = 55;

    List<Map<String, dynamic>> exercises = [];

    if (goalType == 'LOSE_WEIGHT') {
      // Adjust calories based on BMI
      if (isObese) {
        targetCal = 1400;
        targetProtein = 130;
        targetCarbs = 150;
        targetFat = 40;
      } else if (isOverweight) {
        targetCal = 1600;
        targetProtein = 120;
        targetCarbs = 180;
        targetFat = 44;
      } else {
        targetCal = 1800;
        targetProtein = 110;
        targetCarbs = 210;
        targetFat = 50;
      }

      // Exercise recommendations: low-impact if obese/senior
      if (isObese || isSenior) {
        exercises = [
          {
            'name': 'Đi bộ',
            'duration': 40,
            'frequency': '5 lần/tuần',
            'intensity': 'Nhẹ',
            'instructions': [
              'Bắt đầu với tốc độ thoải mái, không cần đi nhanh.',
              'Giữ thẳng lưng, vai thả lỏng, tay đung đưa tự nhiên.',
              'Hít thở đều đặn, thở bằng mũi khi có thể.',
              'Chọn địa hình bằng phẳng, tránh dốc cao để bảo vệ khớp.',
              'Mang giày thoải mái có đệm lót tốt.',
            ],
          },
          {
            'name': 'Bơi lội',
            'duration': 30,
            'frequency': '3 lần/tuần',
            'intensity': 'Vừa phải',
            'instructions': [
              'Khởi động 5–10 phút trước khi xuống nước.',
              'Thực hiện kiểu bơi sải hoặc bơi ngực.',
              'Luân phiên bơi tích cực 2 phút và nghỉ 1 phút.',
              'Bơi lội rất nhẹ nhàng với khớp, phù hợp khi có cân nặng cao.',
              'Kết thúc bằng 5 phút bơi thư giãn.',
            ],
          },
          {
            'name': 'Đạp xe tại chỗ',
            'duration': 25,
            'frequency': '4 lần/tuần',
            'intensity': 'Nhẹ đến vừa',
            'instructions': [
              'Điều chỉnh ghế xe để chân gần duỗi thẳng khi đạp.',
              'Bắt đầu cường độ thấp, tăng dần sau 2 tuần.',
              'Duy trì nhịp tim ở mức 50–65% nhịp tim tối đa.',
              'Tập đều đặn hơn là tập cường độ cao mà không thường xuyên.',
            ],
          },
        ];
      } else {
        exercises = [
          {
            'name': 'Chạy bộ nhẹ (Jogging)',
            'duration': 30,
            'frequency': '4 lần/tuần',
            'intensity': 'Vừa phải',
            'instructions': [
              'Khởi động 5 phút: đi bộ nhanh và kéo giãn cơ.',
              'Chạy nhẹ ở tốc độ có thể nói chuyện được.',
              'Giữ nhịp tim ở 60–75% nhịp tim tối đa.',
              'Tăng thời gian hoặc tốc độ mỗi tuần khoảng 10%.',
              'Kết thúc 5 phút đi bộ thả lỏng.',
            ],
          },
          {
            'name': 'HIIT (Cardio cường độ cao ngắt quãng)',
            'duration': 20,
            'frequency': '3 lần/tuần',
            'intensity': 'Cao',
            'instructions': [
              'Khởi động 5 phút trước khi bắt đầu.',
              'Thực hiện 8 vòng: 20 giây cường độ tối đa, 10 giây nghỉ.',
              'Các bài: burpees, jumping jacks, squat, leo núi.',
              'Nghỉ ít nhất 1 ngày giữa các buổi HIIT.',
              'Không tập HIIT nếu cơ thể đang mệt mỏi hoặc đau nhức.',
            ],
          },
          {
            'name': 'Yoga Vinyasa',
            'duration': 45,
            'frequency': '2 lần/tuần',
            'intensity': 'Nhẹ đến vừa',
            'instructions': [
              'Thực hiện các tư thế nối tiếp nhau theo hơi thở.',
              'Tập trung vào tư thế plank, chó mặt xuống, chiến binh.',
              'Giữ mỗi tư thế 5 hơi thở sâu.',
              'Kết thúc bằng 10 phút thiền định và hít thở sâu.',
            ],
          },
        ];
      }
    } else if (goalType == 'GAIN_MUSCLE') {
      targetCal = 2500;
      targetProtein = 218;
      targetCarbs = 250;
      targetFat = 69;

      exercises = [
        {
          'name': 'Tập tạ (Strength Training)',
          'duration': 60,
          'frequency': '4 lần/tuần',
          'intensity': 'Cao',
          'instructions': [
            'Tập nhóm cơ ngực & vai (Thứ 2), lưng & tay (Thứ 4), chân (Thứ 6).',
            'Thực hiện 3–4 set, mỗi set 8–12 lần.',
            'Nghỉ 60–90 giây giữa các set.',
            'Tăng trọng lượng dần (Progressive Overload).',
            'Ưu tiên kỹ thuật đúng hơn là trọng lượng nặng.',
          ],
        },
        {
          'name': 'Squat & Deadlift',
          'duration': 45,
          'frequency': '2 lần/tuần',
          'intensity': 'Cao',
          'instructions': [
            'Khởi động kỹ trước khi tập các bài nặng này.',
            'Squat: Lưng thẳng, gối không vượt mũi chân, xuống song song sàn.',
            'Deadlift: Giữ thanh tạ sát cơ thể, không khom lưng.',
            'Bắt đầu với trọng lượng nhẹ để làm quen tư thế.',
            'Sử dụng dây lưng bảo hộ khi tập nặng.',
          ],
        },
        {
          'name': 'Hít xà & Chống đẩy',
          'duration': 30,
          'frequency': '3 lần/tuần',
          'intensity': 'Vừa phải',
          'instructions': [
            'Hít xà: Bám rộng hơn vai, kéo người lên đến cằm qua thanh.',
            'Chống đẩy: Tay rộng hơn vai, giữ thẳng lưng từ đầu đến gót.',
            'Mục tiêu: 3 set x 8–15 lần mỗi bài.',
            'Nghỉ 1 phút giữa các set.',
          ],
        },
      ];
    } else if (goalType == 'IMPROVE_SLEEP') {
      targetCal = 1900;
      targetProtein = 95;
      targetCarbs = 261;
      targetFat = 53;

      exercises = [
        {
          'name': 'Yoga Phục hồi & Thư giãn',
          'duration': 30,
          'frequency': '5 lần/tuần',
          'intensity': 'Nhẹ',
          'instructions': [
            'Tập vào buổi tối, 1–2 giờ trước khi ngủ.',
            'Các tư thế: Child\'s Pose, Reclining Butterfly, Legs Up The Wall.',
            'Tập trung vào hơi thở sâu và thư giãn hoàn toàn.',
            'Không tập mạnh hoặc cardio cường độ cao sau 7 giờ tối.',
          ],
        },
        {
          'name': 'Thiền định (Mindfulness Meditation)',
          'duration': 15,
          'frequency': 'Hàng ngày',
          'intensity': 'Nhẹ',
          'instructions': [
            'Tìm không gian yên tĩnh, ngồi thoải mái hoặc nằm.',
            'Nhắm mắt, tập trung vào hơi thở ra vào.',
            'Khi có suy nghĩ xen vào, nhẹ nhàng đưa sự chú ý trở lại hơi thở.',
            'Dùng ứng dụng hướng dẫn thiền nếu mới bắt đầu.',
          ],
        },
        {
          'name': 'Đi bộ buổi tối',
          'duration': 20,
          'frequency': '4 lần/tuần',
          'intensity': 'Nhẹ',
          'instructions': [
            'Đi bộ thư thái sau bữa tối khoảng 30 phút.',
            'Tránh ánh sáng xanh từ điện thoại trong lúc đi bộ.',
            'Hít thở không khí tươi và thư giãn tinh thần.',
            'Giúp hạ nhiệt độ cơ thể, tạo điều kiện cho giấc ngủ sâu hơn.',
          ],
        },
      ];
    } else {
      // STAY_HEALTHY or default
      targetCal = 2000;
      targetProtein = 125;
      targetCarbs = 250;
      targetFat = 55;

      exercises = [
        {
          'name': 'Đi bộ nhanh',
          'duration': 30,
          'frequency': '5 lần/tuần',
          'intensity': 'Vừa phải',
          'instructions': [
            'Duy trì tốc độ đủ nhanh để tăng nhịp tim nhẹ.',
            'Đưa tay ra sau người khi bước dài hơn.',
            'Đặt mục tiêu 8.000–10.000 bước mỗi ngày.',
            'Thích hợp mọi lứa tuổi và cấp độ thể lực.',
          ],
        },
        {
          'name': 'Bài tập thể dục toàn thân',
          'duration': 40,
          'frequency': '3 lần/tuần',
          'intensity': 'Vừa phải',
          'instructions': [
            'Gồm: Squat, Lunge, Push-up, Plank, Bridge.',
            'Mỗi bài 3 set × 12 lần, nghỉ 45 giây giữa set.',
            'Không cần dụng cụ, có thể tập tại nhà.',
            'Tập đều đặn 3 buổi/tuần cho kết quả tốt nhất.',
          ],
        },
        {
          'name': 'Giãn cơ & Linh hoạt (Stretching)',
          'duration': 15,
          'frequency': 'Hàng ngày',
          'intensity': 'Nhẹ',
          'instructions': [
            'Thực hiện sau khi thức dậy hoặc sau tập luyện.',
            'Giữ mỗi tư thế giãn 20–30 giây.',
            'Tập trung vào cổ, vai, lưng, hông và chân.',
            'Không rướn mình quá mức gây đau.',
          ],
        },
      ];
    }

    return {
      'dietPlan': {
        'targetCalories': targetCal,
        'protein': targetProtein,
        'carbs': targetCarbs,
        'fat': targetFat,
        'notes': _buildDietNotes(goalType, bmi, age),
      },
      'exercises': exercises,
    };
  }

  List<String> _buildDietNotes(String goalType, double? bmi, int age) {
    final List<String> notes = [];
    if (bmi != null && bmi >= 25.0) {
      notes.add('Hạn chế đường, thực phẩm chế biến sẵn và đồ uống có đường.');
    }
    if (bmi != null && bmi < 18.5) {
      notes.add('Tăng cường thực phẩm giàu năng lượng lành mạnh: quả hạch, bơ, ngũ cốc nguyên hạt.');
    }
    if (age >= 55) {
      notes.add('Ưu tiên thực phẩm giàu Canxi và Vitamin D để bảo vệ xương.');
    }
    if (goalType == 'GAIN_MUSCLE') {
      notes.add('Ăn protein trong vòng 30 phút sau tập luyện để phục hồi cơ tối ưu.');
    }
    if (goalType == 'IMPROVE_SLEEP') {
      notes.add('Tránh caffeine sau 14h và bữa ăn nặng trong 3 giờ trước khi ngủ.');
      notes.add('Thực phẩm giúp ngủ ngon: cherry, chuối, sữa ấm, yến mạch.');
    }
    if (notes.isEmpty) {
      notes.add('Ưu tiên thực phẩm nguyên chất, rau xanh, trái cây và uống đủ 2 lít nước/ngày.');
    }
    return notes;
  }

  // ── Data loading ────────────────────────────────────────────────────────────
  Future<void> _loadGoalData() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null || user.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    Map<String, dynamic>? activeGoal;
    Map<String, dynamic>? recommendations;

    // 1. Try server first
    try {
      final serverGoalResp = await _goalService.getActiveGoal(user.userId!);
      if (serverGoalResp != null && serverGoalResp.statusCode == 200) {
        final data = serverGoalResp.data;
        activeGoal = data is Map<String, dynamic> ? data : null;
      }
    } catch (_) {}

    // 2. Fall back to local SQLite
    if (activeGoal == null) {
      final dbGoal = await _dbHelper.getActiveGoal(user.userId!);
      if (dbGoal != null) {
        activeGoal = _normalizeGoal(dbGoal);
      }
    }

    // 3. Load recommendations
    if (activeGoal != null) {
      final goalType = activeGoal['goalType'] as String? ?? '';
      try {
        final recResp = await _goalService.getRecommendations(user.userId!);
        if (recResp != null && recResp.statusCode == 200) {
          final rd = recResp.data;
          recommendations = rd is Map<String, dynamic> ? rd : null;
        }
      } catch (_) {}
      recommendations ??= _getLocalRecommendations(goalType, user);
    }

    if (mounted) {
      setState(() {
        _activeGoal = activeGoal;
        _recommendations = recommendations;
        _isLoading = false;
      });
    }
  }

  // ── Save goal ───────────────────────────────────────────────────────────────
  Future<void> _saveGoal(String goalType, double targetValue, User user) async {
    final now = DateTime.now();
    final startDate = DateFormat('yyyy-MM-dd').format(now);
    final endDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 90)));

    final goalData = {
      'goalType': goalType,
      'targetValue': targetValue,
      'startDate': startDate,
      'endDate': endDate,
      'status': 'ACTIVE',
    };

    // Save locally always
    await _dbHelper.insertGoal({
      'user_id': user.userId,
      'goal_type': goalType,
      'target_value': targetValue,
      'start_date': startDate,
      'end_date': endDate,
      'status': 'ACTIVE',
    });

    // Try server
    try {
      await _goalService.saveGoal({...goalData, 'userId': user.userId});
    } catch (_) {}

    NotificationService().showNotification(
      id: 50,
      title: 'Mục tiêu đã được lưu!',
      body: 'Đã thiết lập mục tiêu "${_goalTypeLabel(goalType)}" thành công.',
    );

    await _loadGoalData();
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────
  String _goalTypeLabel(String type) {
    switch (type) {
      case 'LOSE_WEIGHT': return 'Giảm cân';
      case 'GAIN_MUSCLE': return 'Tăng cơ bắp';
      case 'IMPROVE_SLEEP': return 'Cải thiện giấc ngủ';
      case 'STAY_HEALTHY': return 'Duy trì sức khỏe';
      default: return type;
    }
  }

  Color _goalTypeColor(String? type) {
    switch (type) {
      case 'LOSE_WEIGHT': return const Color(0xFFEF4444);
      case 'GAIN_MUSCLE': return const Color(0xFF8B5CF6);
      case 'IMPROVE_SLEEP': return const Color(0xFF3B82F6);
      case 'STAY_HEALTHY': return const Color(0xFF10B981);
      default: return const Color(0xFF0F75F4);
    }
  }

  IconData _goalTypeIcon(String? type) {
    switch (type) {
      case 'LOSE_WEIGHT': return Icons.local_fire_department;
      case 'GAIN_MUSCLE': return Icons.fitness_center;
      case 'IMPROVE_SLEEP': return Icons.bedtime;
      case 'STAY_HEALTHY': return Icons.favorite;
      default: return Icons.track_changes;
    }
  }

  // ── Build: Physical Profile Card ───────────────────────────────────────────
  Widget _buildPhysicalProfileCard(User? user) {
    final bmi = _calcBmi(user);
    final height = user?.height;
    final weight = user?.weight;
    final gender = user?.gender;
    final age = _calcAge(user);

    String genderDisplay = 'Không rõ';
    if (gender == 'MALE' || gender == 'male' || gender?.toLowerCase() == 'nam') {
      genderDisplay = 'Nam';
    } else if (gender == 'FEMALE' || gender == 'female' || gender?.toLowerCase() == 'nữ') {
      genderDisplay = 'Nữ';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3C), Color(0xFF2D3561)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1F3C).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'HỒ SƠ THỂ CHẤT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildProfileStat(
                'Chiều cao',
                height != null ? '${height.toStringAsFixed(0)} cm' : '--',
                Icons.height,
              ),
              const SizedBox(width: 12),
              _buildProfileStat(
                'Cân nặng',
                weight != null ? '${weight.toStringAsFixed(1)} kg' : '--',
                Icons.monitor_weight_outlined,
              ),
              const SizedBox(width: 12),
              _buildProfileStat(
                'Giới tính',
                genderDisplay,
                Icons.wc,
              ),
              const SizedBox(width: 12),
              _buildProfileStat(
                'Tuổi',
                user?.dateOfBirth != null ? '$age tuổi' : '--',
                Icons.cake_outlined,
              ),
            ],
          ),
          if (bmi != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉ số BMI',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bmi.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bmiColor(bmi).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _bmiColor(bmi).withAlpha(80)),
                    ),
                    child: Text(
                      _bmiCategory(bmi),
                      style: TextStyle(
                        color: _bmiColor(bmi),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cập nhật chiều cao & cân nặng trong hồ sơ để xem chỉ số BMI.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Build: Active Goal Card ─────────────────────────────────────────────────
  Widget _buildActiveGoalCard(Map<String, dynamic> goal) {
    final goalType = goal['goalType'] as String? ?? '';
    final color = _goalTypeColor(goalType);
    final icon = _goalTypeIcon(goalType);
    final label = _goalTypeLabel(goalType);
    final targetValue = goal['targetValue'];
    final startDate = goal['startDate'] as String?;
    final endDate = goal['endDate'] as String?;

    String dateRange = '';
    if (startDate != null && endDate != null) {
      try {
        final s = DateTime.parse(startDate);
        final e = DateTime.parse(endDate);
        dateRange = '${DateFormat('dd/MM/yyyy').format(s)} → ${DateFormat('dd/MM/yyyy').format(e)}';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ĐANG HOẠT ĐỘNG',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF111111),
                  ),
                ),
                if (targetValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Mục tiêu: $targetValue',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
                if (dateRange.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateRange,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: _confirmDeleteGoal,
            tooltip: 'Hủy mục tiêu',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy mục tiêu'),
        content: const Text('Bạn có chắc chắn muốn hủy mục tiêu hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy mục tiêu', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && _activeGoal != null) {
      final id = _activeGoal!['id'];
      if (id != null) {
        await _dbHelper.deleteGoal(id as int);
      }
      setState(() {
        _activeGoal = null;
        _recommendations = null;
      });
    }
  }

  // ── Build: Set Goal Button ──────────────────────────────────────────────────
  Widget _buildSetGoalSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHỌN MỤC TIÊU SỨC KHỎE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...['LOSE_WEIGHT', 'GAIN_MUSCLE', 'IMPROVE_SLEEP', 'STAY_HEALTHY']
            .map((type) => _buildGoalOption(type, user)),
      ],
    );
  }

  Widget _buildGoalOption(String type, User? user) {
    final color = _goalTypeColor(type);
    final icon = _goalTypeIcon(type);
    final label = _goalTypeLabel(type);
    final descriptions = {
      'LOSE_WEIGHT': 'Giảm mỡ, cải thiện vóc dáng và sức khỏe tim mạch',
      'GAIN_MUSCLE': 'Tăng khối lượng cơ, cải thiện sức mạnh và trao đổi chất',
      'IMPROVE_SLEEP': 'Cải thiện chất lượng giấc ngủ và năng lượng ban ngày',
      'STAY_HEALTHY': 'Duy trì sức khỏe toàn diện và lối sống lành mạnh',
    };

    return GestureDetector(
      onTap: () => _showSetGoalDialog(type, user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEBECEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descriptions[type] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showSetGoalDialog(String goalType, User? user) {
    final color = _goalTypeColor(goalType);
    final label = _goalTypeLabel(goalType);
    final targetController = TextEditingController();

    // Suggest target based on goal type and BMI
    final bmi = _calcBmi(user);
    String hint = '';
    String unit = '';
    switch (goalType) {
      case 'LOSE_WEIGHT':
        final w = user?.weight ?? 70.0;
        hint = (w - 5).toStringAsFixed(1);
        unit = 'kg (cân nặng mục tiêu)';
        break;
      case 'GAIN_MUSCLE':
        final w = user?.weight ?? 60.0;
        hint = (w + 3).toStringAsFixed(1);
        unit = 'kg (cân nặng mục tiêu)';
        break;
      case 'IMPROVE_SLEEP':
        hint = '8';
        unit = 'giờ/đêm (mục tiêu giấc ngủ)';
        break;
      case 'STAY_HEALTHY':
        if (bmi != null) {
          hint = bmi.toStringAsFixed(1);
        } else {
          hint = '22.5';
        }
        unit = 'BMI mục tiêu';
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(_goalTypeIcon(goalType), color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập giá trị mục tiêu của bạn:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: hint,
                helperText: unit,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(targetController.text);
              if (val == null) return;
              Navigator.pop(ctx);
              if (user != null) {
                await _saveGoal(goalType, val, user);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đặt mục tiêu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build: Diet Plan Card ───────────────────────────────────────────────────
  Widget _buildDietPlanCard(Map<String, dynamic> dietPlan, Color themeColor) {
    final targetCal = dietPlan['targetCalories'] ?? 2000;
    final protein = dietPlan['protein'] ?? 125.0;
    final carbs = dietPlan['carbs'] ?? 250.0;
    final fat = dietPlan['fat'] ?? 55.0;
    final notes = (dietPlan['notes'] as List?)?.cast<String>() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant_menu, color: themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'KẾ HOẠCH DINH DƯỠNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calorie target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Năng lượng mục tiêu',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '$targetCal kcal/ngày',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Macro row
          Row(
            children: [
              _buildMacroChip('Đạm', '${protein.toStringAsFixed(0)}g', const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              _buildMacroChip('Carbs', '${carbs.toStringAsFixed(0)}g', const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildMacroChip('Chất béo', '${fat.toStringAsFixed(0)}g', const Color(0xFFEF4444)),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý dinh dưỡng:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Expanded(
                        child: Text(
                          note,
                          style: const TextStyle(color: Color(0xFF495057), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color.withAlpha(180), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build: Exercise List ────────────────────────────────────────────────────
  Widget _buildExercisesCard(List exercises, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.directions_run, color: themeColor, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'BÀI TẬP GỢI Ý',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...exercises.map((ex) {
          final e = ex as Map<String, dynamic>;
          final name = e['name'] as String? ?? '';
          final duration = e['duration'] ?? 30;
          final freq = e['frequency'] as String? ?? '';
          final intensity = e['intensity'] as String? ?? '';
          final instructions = (e['instructions'] as List?)?.cast<String>() ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBECEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_run, color: themeColor, size: 20),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '$duration phút  •  $freq  •  Cường độ: $intensity',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hướng dẫn bài tập:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 6),
                ...instructions.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$idx. ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: Color(0xFF495057),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoRecommendationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.track_changes, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Thiết lập mục tiêu sức khỏe để nhận đề xuất bài tập và chế độ ăn dinh dưỡng!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser();
    final goalType = _activeGoal?['goalType'] as String?;
    final themeColor = _goalTypeColor(goalType);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Mục tiêu sức khỏe',
          style: TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _loadGoalData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F75F4)))
          : RefreshIndicator(
              onRefresh: _loadGoalData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Physical Profile Card
                    _buildPhysicalProfileCard(user),
                    const SizedBox(height: 24),

                    // 2. Active Goal Card or Goal Selection
                    if (_activeGoal != null) ...[
                      _buildActiveGoalCard(_activeGoal!),
                      const SizedBox(height: 24),
                      // 3. Recommendations
                      if (_recommendations != null) ...[
                        const Text(
                          'ĐỀ XUẤT CHO BẠN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Diet plan
                        if (_recommendations!['dietPlan'] != null) ...[
                          _buildDietPlanCard(
                            _recommendations!['dietPlan'] as Map<String, dynamic>,
                            themeColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Exercises
                        if (_recommendations!['exercises'] != null &&
                            (_recommendations!['exercises'] as List).isNotEmpty) ...[
                          _buildExercisesCard(
                            _recommendations!['exercises'] as List,
                            themeColor,
                          ),
                        ],
                      ] else
                        _buildNoRecommendationsCard(),
                    ] else ...[
                      _buildSetGoalSection(user),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
