import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/activity.dart';

class ActivityController {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Activity?> getTodayActivity(int userId) =>
      _db.getTodayActivity(userId);

  Future<List<Activity>> getRecentActivities(int userId, {int days = 7}) =>
      _db.getRecentActivities(userId, days: days);

  /// Ghi đè hoặc tạo mới bản ghi activity hôm nay
  Future<int> upsertTodayActivity({
    required int userId,
    required int steps,
    double distance = 0,
    int caloriesBurned = 0,
  }) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _db.upsertTodayActivity(
      Activity(
        userId: userId,
        date: today,
        steps: steps,
        distance: distance,
        caloriesBurned: caloriesBurned,
        source: 'manual',
      ),
    );
  }
}
