class Meal {
  final int? logId;
  final int userId;
  final String date;
  final String mealType;
  final String foodName;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  Meal({
    this.logId,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      logId: map['log_id'],
      userId: map['user_id'],
      date: map['date'],
      mealType: map['meal_type'],
      foodName: map['food_name'] ?? map['name'] ?? 'Không rõ',
      calories: map['calories'] ?? 0,
      protein: map['protein'] != null ? (map['protein'] as num).toDouble() : null,
      carbs: map['carbs'] != null ? (map['carbs'] as num).toDouble() : null,
      fat: map['fat'] != null ? (map['fat'] as num).toDouble() : null,
    );
  }

  String get mealTypeLabel {
    switch (mealType) {
      case 'Breakfast': return 'Bữa sáng';
      case 'Lunch': return 'Bữa trưa';
      case 'Dinner': return 'Bữa tối';
      case 'Snack': return 'Bữa phụ';
      default: return mealType;
    }
  }
}
