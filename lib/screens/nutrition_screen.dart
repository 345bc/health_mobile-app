import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/services/api_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<dynamic> _mealsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();

  int _targetCalories = 2000;
  double _targetProtein = 125.0;
  double _targetCarbs = 250.0;
  double _targetFat = 55.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeals();
    });
  }

  Future<void> _loadMeals() async {
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

    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      double bmi = 22.0;
      final endUser = user['endUser'];
      final heightVal = endUser != null ? endUser['height'] : null;
      final weightVal = endUser != null ? endUser['weight'] : null;
      if (heightVal != null && weightVal != null && heightVal > 0) {
        double h = (heightVal as num).toDouble();
        if (h > 10) {
          h = h / 100.0;
        }
        bmi = (weightVal as num).toDouble() / (h * h);
      }
      String goalType = 'STAY_HEALTHY';
      if (bmi > 24.9) {
        goalType = 'LOSE_WEIGHT';
      } else if (bmi < 18.5) {
        goalType = 'GAIN_MUSCLE';
      }

      if (goalType == 'LOSE_WEIGHT') {
        _targetCalories = 1600;
        _targetProtein = 120.0;
        _targetCarbs = 180.0;
        _targetFat = 44.0;
      } else if (goalType == 'GAIN_MUSCLE') {
        _targetCalories = 2500;
        _targetProtein = 218.0;
        _targetCarbs = 250.0;
        _targetFat = 69.0;
      } else {
        _targetCalories = 2000;
        _targetProtein = 125.0;
        _targetCarbs = 250.0;
        _targetFat = 55.0;
      }
    } catch (e) {
      debugPrint("Lỗi tải mục tiêu cho dinh dưỡng: $e");
    }

    try {
      final meals = await ApiService.getNutritionLogs(userId, dateStr);
      setState(() {
        _mealsList = meals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải nhật ký dinh dưỡng: $e");
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "").trim();
        _isLoading = false;
      });
    }
  }

  void _showAddMealDialog(String mealType) {
    final foodNameController = TextEditingController();
    final calorieController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFF0F75F4)),
              const SizedBox(width: 8),
              Text('Thêm $mealType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(foodNameController, 'Tên món ăn', Icons.restaurant_menu),
                const SizedBox(height: 12),
                _buildDialogField(calorieController, 'Kcal (Calo)', Icons.local_fire_department, isNumber: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDialogField(proteinController, 'Đạm (g)', Icons.egg_outlined, isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDialogField(carbsController, 'Carbs (g)', Icons.grain_outlined, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDialogField(fatController, 'Chất béo (g)', Icons.opacity, isNumber: true),
              ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final String foodName = foodNameController.text.trim();
                final int calories = int.tryParse(calorieController.text.trim()) ?? 0;
                final double protein = double.tryParse(proteinController.text.trim()) ?? 0.0;
                final double carbs = double.tryParse(carbsController.text.trim()) ?? 0.0;
                final double fat = double.tryParse(fatController.text.trim()) ?? 0.0;

                if (foodName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên món ăn')),
                  );
                  return;
                }

                final user = Provider.of<UserProvider>(context, listen: false).getUser();
                if (user == null) return;
                final int userId = user['id'] ?? user['userId'] ?? 0;

                final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  await ApiService.createNutritionLog({
                    'userId': userId,
                    'date': dateStr,
                    'mealType': mealType,
                    'foodName': foodName,
                    'calories': calories,
                    'protein': protein,
                    'carbs': carbs,
                    'fat': fat,
                  });

                  NotificationService().showNotification(
                    id: 20,
                    title: "Ghi nhận dinh dưỡng",
                    body: "Món ăn '$foodName' đã được thêm thành công.",
                  );

                  _loadMeals();
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi thêm món ăn: ${e.toString().replaceAll("Exception: ", "").trim()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _deleteMeal(int logId) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.deleteNutritionLog(logId);
      _loadMeals();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa món ăn: ${e.toString().replaceAll("Exception: ", "").trim()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Đang tải...')),
      );
    }
    int totalCalories = 0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (var m in _mealsList) {
      totalCalories += (m['calories'] as num?)?.toInt() ?? 0;
      totalProtein += (m['protein'] as num?)?.toDouble() ?? 0.0;
      totalCarbs += (m['carbs'] as num?)?.toDouble() ?? 0.0;
      totalFat += (m['fat'] as num?)?.toDouble() ?? 0.0;
    }

    final double calProgress = (totalCalories / _targetCalories).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dinh dưỡng',
          style: TextStyle(color: Color(0xFF111111), fontSize: 18, fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F75F4)),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadMeals,
          ),
        ],
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
                          onPressed: _loadMeals,
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
                  onRefresh: _loadMeals,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(),
                        const SizedBox(height: 20),
                        _buildSummaryCard(totalCalories, calProgress),
                        const SizedBox(height: 20),
                        _buildMacrosProgress(totalProtein, totalCarbs, totalFat),
                        const SizedBox(height: 28),
                        const Text(
                          'BỮA ĂN HÔM NAY',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 16),
                        _buildMealCategoryList('Breakfast', 'Bữa sáng', Icons.wb_twilight, Colors.orange),
                        const SizedBox(height: 16),
                        _buildMealCategoryList('Lunch', 'Bữa trưa', Icons.wb_sunny_outlined, Colors.blue),
                        const SizedBox(height: 16),
                        _buildMealCategoryList('Dinner', 'Bữa tối', Icons.nights_stay_outlined, Colors.indigo),
                        const SizedBox(height: 16),
                        _buildMealCategoryList('Snack', 'Bữa phụ', Icons.local_cafe_outlined, Colors.teal),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            _loadMeals();
          },
        ),
        Text(
          DateFormat('dd MMMM, yyyy').format(_selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            });
            _loadMeals();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int totalCalories, double calProgress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalCalories',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0F75F4), height: 1),
              ),
              const SizedBox(height: 4),
              const Text('Kcal đã tiêu thụ', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Mục tiêu: $_targetCalories Kcal', style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A4A))),
            ],
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: calProgress,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F75F4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosProgress(double protein, double carbs, double fat) {
    return Row(
      children: [
        Expanded(child: _macroItem('Đạm', protein, _targetProtein, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _macroItem('Carbs', carbs, _targetCarbs, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _macroItem('Béo', fat, _targetFat, Colors.teal)),
      ],
    );
  }

  Widget _macroItem(String label, double current, double target, Color color) {
    final double percent = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
          const SizedBox(height: 6),
          Text('${current.toStringAsFixed(1)}/${target.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: const Color(0xFFEBECEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMealCategoryList(String type, String title, IconData icon, Color color) {
    final categoryMeals = _mealsList.where((m) => m['mealType'] == type || m['meal_type'] == type).toList();
    int categoryCalories = 0;
    for (var m in categoryMeals) {
      categoryCalories += (m['calories'] as num?)?.toInt() ?? 0;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBECEE), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.8),
        child: Material(
          color: Colors.white,
          child: ExpansionTile(
            initiallyExpanded: categoryMeals.isNotEmpty,
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111111)),
            ),
            subtitle: Text(
              '$categoryCalories kcal • ${categoryMeals.length} món',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0F75F4)),
              onPressed: () => _showAddMealDialog(type),
            ),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            children: [
              if (categoryMeals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Chưa ghi nhận món ăn nào',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFADB5BD)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categoryMeals.length,
                  itemBuilder: (ctx, index) {
                    final meal = categoryMeals[index];
                    final int logId = meal['id'] ?? meal['logId'] ?? meal['log_id'] ?? 0;
                    final String foodName = meal['foodName'] ?? meal['food_name'] ?? meal['name'] ?? 'Không rõ';
                    final int calories = meal['calories'] ?? 0;
                    final proteinVal = meal['protein'];
                    final carbsVal = meal['carbs'];
                    final fatVal = meal['fat'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foodName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (proteinVal != null || carbsVal != null || fatVal != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'P: ${proteinVal?.toStringAsFixed(1) ?? "0"}g  •  C: ${carbsVal?.toStringAsFixed(1) ?? "0"}g  •  F: ${fatVal?.toStringAsFixed(1) ?? "0"}g',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D)),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Text(
                            '+$calories kcal',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteMeal(logId),
                          ),
                        ],
                      ),
                    );
                  },
                )
            ],
          ),
        ),
      ),
    );
  }
}
