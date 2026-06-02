import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/activity.dart';
import 'package:frontend/services/activity_service.dart';
import 'package:frontend/services/api_service.dart';

class ActivityController {
  final DatabaseHelper _db = DatabaseHelper();
  final ActivityService _activityService = ActivityService(ApiService());

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
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing = await _db.getTodayActivity(userId);
    
    final activity = Activity(
      userId: userId,
      date: today,
      steps: steps,
      distance: distance,
      caloriesBurned: caloriesBurned,
      source: 'manual',
    );

    final int localId = await _db.upsertTodayActivity(activity);

    // Sync to server
    try {
      final db = await _db.database;
      if (existing != null && existing.activityId != null && existing.activityId! > 0) {
        // We try to update on the server
        await _activityService.updateActivity(existing.activityId!, {
          'userId': userId,
          'date': today,
          'steps': steps,
          'distance': distance,
          'caloriesBurned': caloriesBurned,
          'source': 'manual'
        });
      } else {
        // Create on the server
        final response = await _activityService.createActivity({
          'userId': userId,
          'date': today,
          'steps': steps,
          'distance': distance,
          'caloriesBurned': caloriesBurned,
          'source': 'manual'
        });
        
        if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
          final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
          final data = body['data'] ?? body;
          final serverId = data['id'];
          if (serverId != null) {
            // Update SQLite primary key to match backend server ID
            await db.delete(
              'activities',
              where: 'activity_id = ? AND activity_id != ?',
              whereArgs: [serverId, localId],
            );
            await db.update(
              'activities',
              {'activity_id': serverId},
              where: 'activity_id = ?',
              whereArgs: [localId],
            );
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ hoạt động lên server: $e");
    }

    return localId;
  }
}
