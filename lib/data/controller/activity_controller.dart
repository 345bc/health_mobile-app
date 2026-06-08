import 'package:dio/dio.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/activity.dart';
import 'package:frontend/services/activity_service.dart';
import 'package:frontend/services/api_service.dart';

class ActivityController {
  final DatabaseHelper _db;
  final ActivityService _activityService;

  ActivityController({
    DatabaseHelper? db,
    ActivityService? activityService,
  })  : _db = db ?? DatabaseHelper(),
        _activityService = activityService ?? ActivityService(ApiService());

  Future<Activity?> getTodayActivity(int userId) =>
      _db.getTodayActivity(userId);

  Future<Activity?> getActivityForDate(int userId, String date) =>
      _db.getActivityForDate(userId, date);

  Future<List<Activity>> getRecentActivities(int userId, {int days = 7}) =>
      _db.getRecentActivities(userId, days: days);

  /// Ghi đè hoặc tạo mới bản ghi activity hôm nay hoặc ngày chỉ định
  Future<int> upsertTodayActivity({
    required int userId,
    required int steps,
    double distance = 0,
    int caloriesBurned = 0,
    String? date,
  }) async {
    final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final existing = await _db.getActivityForDate(userId, targetDate);
    
    final activity = Activity(
      userId: userId,
      date: targetDate,
      steps: steps,
      distance: distance,
      caloriesBurned: caloriesBurned,
      source: 'manual',
    );

    final int localId = await _db.upsertTodayActivity(activity);

    // Sync to server
    final db = await _db.database;
    if (existing != null && existing.activityId != null && existing.activityId! > 0) {
      // We try to update on the server
      final response = await _activityService.updateActivity(existing.activityId!, {
        'userId': userId,
        'date': targetDate,
        'steps': steps,
        'distance': distance,
        'caloriesBurned': caloriesBurned,
        'source': 'manual'
      });
      if (response == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
    } else {
      // Create on the server
      final response = await _activityService.createActivity({
        'userId': userId,
        'date': targetDate,
        'steps': steps,
        'distance': distance,
        'caloriesBurned': caloriesBurned,
        'source': 'manual'
      });
      
      if (response == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
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

    return localId;
  }
}
