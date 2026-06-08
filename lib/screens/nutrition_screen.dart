import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:frontend/data/models/meal.dart';
import 'package:frontend/data/controller/nutrition_controller.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionController _controller = NutritionController();
  DateTime _selectedDate = DateTime.now();
  List<Meal> _mealsList = [];
  bool _isLoading = true;

  // Goals
  int _targetCalories = 2000;
  double _targetProtein = 50.0;
  double _targetCarbs = 250.0;
  double _targetFat = 70.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeals();
    });
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Load dynamic targets based on user BMI
    try {
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
      print("Lỗi tải mục tiêu cho dinh dưỡng: $e");
    }

    try {
      final meals = await _controller.getMeals(
        userId: user.userId!,
        date: dateStr,
      );
      setState(() {
        _mealsList = meals;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi tải nhật ký dinh dưỡng: $e");
      try {
        final localMeals = await DatabaseHelper().getMealsForDate(user.userId!, dateStr);
        setState(() {
          _mealsList = localMeals;
          _isLoading = false;
        });
      } catch (dbError) {
        print("Lỗi tải local meals: $dbError");
        setState(() {
          _mealsList = [];
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi tải dữ liệu dinh dưỡng từ máy chủ. Hiển thị dữ liệu ngoại tuyến (Offline)."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadMeals();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F75F4),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }

  void _showAddMealDialog() {
    final foodNameController = TextEditingController();
    final calorieController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    String mealType = 'Breakfast';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Ghi nhận bữa ăn mới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: mealType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C757D)),
                      items: const [
                        DropdownMenuItem(value: 'Breakfast', child: Text('Bữa sáng')),
                        DropdownMenuItem(value: 'Lunch', child: Text('Bữa trưa')),
                        DropdownMenuItem(value: 'Dinner', child: Text('Bữa tối')),
                        DropdownMenuItem(value: 'Snack', child: Text('Bữa phụ')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => mealType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogField(foodNameController, 'Tên món ăn', Icons.restaurant_menu),
                const SizedBox(height: 12),
                _buildDialogField(calorieController, 'Kcal (Calo)', Icons.local_fire_department, isNumber: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDialogField(proteinController, 'Đạm (g)', Icons.egg_outlined, isNumber: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDialogField(carbsController, 'Carbs (g)', Icons.grain_outlined, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDialogField(fatController, 'Chất béo (g)', Icons.opacity, isNumber: true),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF6C757D))),
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

                final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  await _controller.addMeal(
                    userId: user.userId!,
                    date: dateStr,
                    mealType: mealType,
                    foodName: foodName,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                  );

                  NotificationService().showNotification(
                    id: 20,
                    title: "Ghi nhận dinh dưỡng",
                    body: "Món ăn '$foodName' đã được thêm thành công.",
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã ghi nhận bữa ăn: $foodName 🎉"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lưu ngoại tuyến thành công. Không thể kết nối với máy chủ để đồng bộ."),
                        backgroundColor: Colors.blueGrey,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  _loadMeals();
                }
              },
              child: const Text('Lưu lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6C757D), size: 18),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _deleteMeal(int? logId) async {
    if (logId == null) return;
    
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhật ký bữa ăn'),
        content: const Text('Bạn có chắc chắn muốn xóa món ăn này khỏi nhật ký?'),
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
        await _controller.deleteMeal(logId);
        NotificationService().showNotification(
          id: 21,
          title: "Xóa bữa ăn",
          body: "Đã xóa món ăn khỏi nhật ký thành công.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xóa bữa ăn thành công."),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xóa ngoại tuyến. Không thể kết nối với máy chủ để đồng bộ."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        _loadMeals();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser();
    if (user == null || user.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Đang tải...')),
      );
    }
    int totalCalories = 0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (var m in _mealsList) {
      totalCalories += m.calories;
      totalProtein += m.protein ?? 0.0;
      totalCarbs += m.carbs ?? 0.0;
      totalFat += m.fat ?? 0.0;
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: const Color(0xFF0F75F4),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F75F4)))
          : RefreshIndicator(
              onRefresh: _loadMeals,
              color: const Color(0xFF0F75F4),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    
                    // Calorie card
                    _buildCalorieCard(totalCalories, calProgress),
                    const SizedBox(height: 24),
                    
                    // Macros section
                    _buildMacrosSection(totalProtein, totalCarbs, totalFat),
                    const SizedBox(height: 32),
                    
                    // Meal categories list
                    const Text(
                      'BỮA ĂN HÔM NAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C757D),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMealCategoryList('Breakfast', 'Bữa sáng', Icons.wb_sunny_outlined, const Color(0xFFD97706)),
                    const SizedBox(height: 12),
                    _buildMealCategoryList('Lunch', 'Bữa trưa', Icons.wb_twilight_outlined, const Color(0xFF0F75F4)),
                    const SizedBox(height: 12),
                    _buildMealCategoryList('Dinner', 'Bữa tối', Icons.nights_stay_outlined, const Color(0xFF6A1B9A)),
                    const SizedBox(height: 12),
                    _buildMealCategoryList('Snack', 'Bữa phụ', Icons.local_cafe_outlined, const Color(0xFF198754)),
                    const SizedBox(height: 24),
                    AlarmReminderCard(userId: user.userId!, type: 'nutrition'),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    String dateLabel = '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selected == today) {
      dateLabel = 'Hôm nay';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Hôm qua';
    } else {
      dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F75F4)),
            onPressed: () => _changeDate(-1),
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Row(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111111)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_month_outlined, color: Color(0xFF0F75F4), size: 18),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios, 
              size: 16, 
              color: selected.isBefore(today) ? const Color(0xFF0F75F4) : Colors.grey.shade400,
            ),
            onPressed: selected.isBefore(today) ? () => _changeDate(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(int total, double progress) {
    final int remaining = (_targetCalories - total).clamp(0, _targetCalories);
    final int percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIÊU THỤ CALO',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$total',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                      ),
                      TextSpan(
                        text: ' / $_targetCalories kcal',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total >= _targetCalories ? 'Đã đạt mục tiêu calo!' : 'Còn thiếu $remaining kcal nữa',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacrosSection(double protein, double carbs, double fat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildMacroItem('Đạm (Protein)', protein, _targetProtein, const Color(0xFFEA4335))),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroItem('Đường (Carbs)', carbs, _targetCarbs, const Color(0xFFFBBC05))),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroItem('Béo (Fat)', fat, _targetFat, const Color(0xFF34A853))),
      ],
    );
  }

  Widget _buildMacroItem(String label, double value, double target, Color color) {
    final double percent = target > 0 ? (value / target).clamp(0.0, 1.0) : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C757D)),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
          ),
          Text(
            '/ ${target.toInt()}g',
            style: const TextStyle(fontSize: 11, color: Color(0xFFADB5BD)),
          ),
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
    final categoryMeals = _mealsList.where((m) => m.mealType == type).toList();
    int categoryCalories = 0;
    for (var m in categoryMeals) {
      categoryCalories += m.calories;
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
                                  meal.foodName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (meal.protein != null || meal.carbs != null || meal.fat != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'P: ${meal.protein?.toStringAsFixed(1) ?? "0"}g  •  C: ${meal.carbs?.toStringAsFixed(1) ?? "0"}g  •  F: ${meal.fat?.toStringAsFixed(1) ?? "0"}g',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D)),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Text(
                            '+${meal.calories} kcal',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteMeal(meal.logId),
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
