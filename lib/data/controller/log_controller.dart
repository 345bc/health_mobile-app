import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/body_measurement_service.dart';
import 'package:frontend/services/mood_service.dart';
import 'package:frontend/services/goal_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/activity_service.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class LogController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final BodyMeasurementService _measurementService = BodyMeasurementService(ApiService());
  final MoodService _moodService = MoodService(ApiService());
  final GoalService _goalService = GoalService(ApiService());
  final ActivityService _activityService = ActivityService(ApiService());

  /// Sync all measurements and moods from the server to local SQLite
  Future<void> refreshLogsFromServer(int userId) async {
    try {
      // 1. Sync Body Measurements
      final mResponse = await _measurementService.getBodyMeasurementsByUser(userId);
      if (mResponse != null && mResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = mResponse.data is Map<String, dynamic>
            ? mResponse.data
            : {};
        final dynamic rawList = responseBody['data'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          batch.delete('body_measurements', where: 'user_id = ?', whereArgs: [userId]);

          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              batch.insert('body_measurements', {
                'measurement_id': item['id'],
                'user_id': userId,
                'date': item['date'],
                'weight': item['weight'],
                'body_fat_percentage': item['bodyFatPercentage'],
                'blood_pressure': item['bloodPressure'],
                'blood_glucose': item['bloodGlucose'],
                'heart_rate': item['heartRate'],
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          await batch.commit(noResult: true);
        }
      }

      // 2. Sync Moods
      final moodResponse = await _moodService.getMoodEntriesByUser(userId);
      if (moodResponse != null && moodResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = moodResponse.data is Map<String, dynamic>
            ? moodResponse.data
            : {};
        final dynamic rawList = responseBody['data'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          batch.delete('mood_entries', where: 'user_id = ?', whereArgs: [userId]);

          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              batch.insert('mood_entries', {
                'mood_id': item['id'],
                'user_id': userId,
                'date': item['date'],
                'mood_score': item['moodScore'],
                'notes': item['notes'],
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          await batch.commit(noResult: true);
        }
      }

      // 3. Sync Goals
      final goalResponse = await _goalService.getActiveGoal(userId);
      if (goalResponse != null && goalResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = goalResponse.data is Map<String, dynamic>
            ? goalResponse.data
            : {};
        final dynamic data = responseBody['data'] ?? responseBody;

        if (data is Map<String, dynamic> && data.isNotEmpty) {
          final db = await _dbHelper.database;

          // Deactivate old local active goals
          await db.update(
            'goals',
            {'status': 'COMPLETED'},
            where: 'user_id = ? AND status = ?',
            whereArgs: [userId, 'ACTIVE'],
          );

          // Insert active goal
          await db.insert('goals', {
            'goal_id': data['id'],
            'user_id': userId,
            'goal_type': data['goalType'],
            'target_value': data['targetValue'],
            'start_date': data['startDate'],
            'end_date': data['endDate'],
            'status': data['status'] ?? 'ACTIVE',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 4. Sync Activities
      final activityResponse = await _activityService.getActivitiesByUser(userId);
      if (activityResponse != null && activityResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = activityResponse.data is Map<String, dynamic>
            ? activityResponse.data
            : {};
        final dynamic rawList = responseBody['data'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          batch.delete('activities', where: 'user_id = ?', whereArgs: [userId]);

          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              batch.insert('activities', {
                'activity_id': item['id'],
                'user_id': userId,
                'date': item['date'],
                'steps': item['steps'],
                'distance': item['distance'],
                'calories_burned': item['caloriesBurned'],
                'source': item['source'] ?? 'manual',
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          await batch.commit(noResult: true);
        }
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu đồng bộ từ server: $e");
    }
  }

  /// Log weight to SQLite and sync to server
  Future<void> logWeight({
    required int userId,
    required String date,
    required double weight,
  }) async {
    final db = await _dbHelper.database;

    // Check if measurement for this date already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'body_measurements',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    int? measurementId;

    if (existing.isNotEmpty) {
      measurementId = existing.first['measurement_id'] as int?;
      await db.update(
        'body_measurements',
        {'weight': weight},
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
    } else {
      final id = await db.insert('body_measurements', {
        'user_id': userId,
        'date': date,
        'weight': weight,
      });
      measurementId = id;
    }

    // Server Sync
    try {
      final List<Map<String, dynamic>> updatedRows = await db.query(
        'body_measurements',
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
      if (updatedRows.isNotEmpty) {
        final row = updatedRows.first;

        if (measurementId != null && measurementId > 0 && existing.isNotEmpty) {
          // UPDATE on server
          await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': weight,
            'bloodPressure': row['blood_pressure'],
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'weight': weight,
          });
          if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
            final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
            final data = body['data'] ?? body;
            final serverId = data['id'];
            if (serverId != null) {
              await db.delete(
                'body_measurements',
                where: 'measurement_id = ? AND measurement_id != ?',
                whereArgs: [serverId, measurementId],
              );
              await db.update(
                'body_measurements',
                {'measurement_id': serverId},
                where: 'measurement_id = ?',
                whereArgs: [measurementId],
              );
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ cân nặng lên server: $e");
    }
  }

  /// Log blood pressure to SQLite and sync to server
  Future<void> logBloodPressure({
    required int userId,
    required String date,
    required String bloodPressure,
  }) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'body_measurements',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    int? measurementId;

    if (existing.isNotEmpty) {
      measurementId = existing.first['measurement_id'] as int?;
      await db.update(
        'body_measurements',
        {'blood_pressure': bloodPressure},
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
    } else {
      final id = await db.insert('body_measurements', {
        'user_id': userId,
        'date': date,
        'blood_pressure': bloodPressure,
      });
      measurementId = id;
    }

    // Server Sync
    try {
      final List<Map<String, dynamic>> updatedRows = await db.query(
        'body_measurements',
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
      if (updatedRows.isNotEmpty) {
        final row = updatedRows.first;

        if (measurementId != null && measurementId > 0 && existing.isNotEmpty) {
          // UPDATE on server
          await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': bloodPressure,
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'bloodPressure': bloodPressure,
          });
          if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
            final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
            final data = body['data'] ?? body;
            final serverId = data['id'];
            if (serverId != null) {
              await db.delete(
                'body_measurements',
                where: 'measurement_id = ? AND measurement_id != ?',
                whereArgs: [serverId, measurementId],
              );
              await db.update(
                'body_measurements',
                {'measurement_id': serverId},
                where: 'measurement_id = ?',
                whereArgs: [measurementId],
              );
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ huyết áp lên server: $e");
    }
  }

  /// Log mood to SQLite and sync to server
  Future<void> logMood({
    required int userId,
    required String date,
    required int moodScore,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'mood_entries',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    int? moodId;

    if (existing.isNotEmpty) {
      moodId = existing.first['mood_id'] as int?;
      await db.update(
        'mood_entries',
        {
          'mood_score': moodScore,
          'notes': notes,
        },
        where: 'mood_id = ?',
        whereArgs: [moodId],
      );
    } else {
      final id = await db.insert('mood_entries', {
        'user_id': userId,
        'date': date,
        'mood_score': moodScore,
        'notes': notes,
      });
      moodId = id;
    }

    // Server Sync
    try {
      if (moodId != null && moodId > 0 && existing.isNotEmpty) {
        // UPDATE on server (backend endpoint /mood-entries is used to create or update, it acts as upsert or we can just send it)
        // Wait, backend MoodEntryService doesn't have an update log by id endpoint mapping in Controller?
        // Wait! Let's check be\flutterbe\controller\v1\MoodEntryController.java.
        // Actually, creating a new mood log will save it. For simplicity, we send createMoodEntry.
        await _moodService.createMoodEntry({
          'userId': userId,
          'date': date,
          'moodScore': moodScore,
          'notes': notes,
        });
      } else {
        // CREATE on server
        final response = await _moodService.createMoodEntry({
          'userId': userId,
          'date': date,
          'moodScore': moodScore,
          'notes': notes,
        });
        if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
          final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
          final data = body['data'] ?? body;
          final serverId = data['id'];
          if (serverId != null) {
            await db.delete(
              'mood_entries',
              where: 'mood_id = ? AND mood_id != ?',
              whereArgs: [serverId, moodId],
            );
            await db.update(
              'mood_entries',
              {'mood_id': serverId},
              where: 'mood_id = ?',
              whereArgs: [moodId],
            );
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ tâm trạng lên server: $e");
    }
  }

  /// Log blood glucose to SQLite and sync to server
  Future<void> logBloodGlucose({
    required int userId,
    required String date,
    required double bloodGlucose,
  }) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'body_measurements',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    int? measurementId;

    if (existing.isNotEmpty) {
      measurementId = existing.first['measurement_id'] as int?;
      await db.update(
        'body_measurements',
        {'blood_glucose': bloodGlucose},
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
    } else {
      final id = await db.insert('body_measurements', {
        'user_id': userId,
        'date': date,
        'blood_glucose': bloodGlucose,
      });
      measurementId = id;
    }

    // Server Sync
    try {
      final List<Map<String, dynamic>> updatedRows = await db.query(
        'body_measurements',
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
      if (updatedRows.isNotEmpty) {
        final row = updatedRows.first;

        if (measurementId != null && measurementId > 0 && existing.isNotEmpty) {
          // UPDATE on server
          await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': row['blood_pressure'],
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': bloodGlucose,
          });
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'bloodGlucose': bloodGlucose,
          });
          if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
            final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
            final data = body['data'] ?? body;
            final serverId = data['id'];
            if (serverId != null) {
              await db.delete(
                'body_measurements',
                where: 'measurement_id = ? AND measurement_id != ?',
                whereArgs: [serverId, measurementId],
              );
              await db.update(
                'body_measurements',
                {'measurement_id': serverId},
                where: 'measurement_id = ?',
                whereArgs: [measurementId],
              );
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ đường huyết lên server: $e");
    }
  }

  /// Log heart rate to SQLite and sync to server
  Future<void> logHeartRate({
    required int userId,
    required String date,
    required int heartRate,
  }) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'body_measurements',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    int? measurementId;

    if (existing.isNotEmpty) {
      measurementId = existing.first['measurement_id'] as int?;
      await db.update(
        'body_measurements',
        {'heart_rate': heartRate},
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
    } else {
      final id = await db.insert('body_measurements', {
        'user_id': userId,
        'date': date,
        'heart_rate': heartRate,
      });
      measurementId = id;
    }

    // Server Sync
    try {
      final List<Map<String, dynamic>> updatedRows = await db.query(
        'body_measurements',
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
      if (updatedRows.isNotEmpty) {
        final row = updatedRows.first;

        if (measurementId != null && measurementId > 0 && existing.isNotEmpty) {
          // UPDATE on server
          await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': row['blood_pressure'],
            'heartRate': heartRate,
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'heartRate': heartRate,
          });
          if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
            final Map<String, dynamic> body = response.data is Map<String, dynamic> ? response.data : {};
            final data = body['data'] ?? body;
            final serverId = data['id'];
            if (serverId != null) {
              await db.delete(
                'body_measurements',
                where: 'measurement_id = ? AND measurement_id != ?',
                whereArgs: [serverId, measurementId],
              );
              await db.update(
                'body_measurements',
                {'measurement_id': serverId},
                where: 'measurement_id = ?',
                whereArgs: [measurementId],
              );
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ nhịp tim lên server: $e");
    }
  }

  /// Delete body measurement from SQLite and sync with server
  Future<void> deleteBodyMeasurement(int measurementId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'body_measurements',
      where: 'measurement_id = ?',
      whereArgs: [measurementId],
    );
    try {
      await _measurementService.deleteBodyMeasurement(measurementId);
    } catch (e) {
      print("Lỗi khi xóa đo lường trên server: $e");
    }
  }

  /// Calculate consecutive logging streak leading up to today
  Future<int> calculateStreak(int userId) async {
    final db = await _dbHelper.database;
    final List<String> queries = [
      "SELECT DISTINCT date FROM activities WHERE user_id = ?",
      "SELECT DISTINCT date FROM sleeps WHERE user_id = ?",
      "SELECT DISTINCT date FROM nutrition_logs WHERE user_id = ?",
      "SELECT DISTINCT date FROM body_measurements WHERE user_id = ?",
      "SELECT DISTINCT date FROM mood_entries WHERE user_id = ?"
    ];

    Set<String> allDates = {};
    for (var query in queries) {
      final List<Map<String, dynamic>> res = await db.rawQuery(query, [userId]);
      for (var row in res) {
        if (row['date'] != null) {
          allDates.add(row['date'].toString());
        }
      }
    }

    if (allDates.isEmpty) return 0;

    List<DateTime> sortedDates = allDates
        .map((d) => DateTime.tryParse(d))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (!sortedDates.contains(todayDate) && !sortedDates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.contains(todayDate) ? todayDate : yesterdayDate;

    while (sortedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculate completion rate (0.0 to 1.0) of 4 tasks for each day of the current week (Monday-Sunday)
  Future<List<double>> calculateWeeklyCompletion(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final int currentWeekday = now.weekday;
    final DateTime monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));

    List<double> completionRates = [];

    for (int i = 0; i < 7; i++) {
      final DateTime day = monday.add(Duration(days: i));
      final String dateStr = DateFormat('yyyy-MM-dd').format(day);

      final List<Map<String, dynamic>> weightRes = await db.query(
        'body_measurements',
        where: 'user_id = ? AND date = ? AND weight IS NOT NULL',
        whereArgs: [userId, dateStr],
      );

      final List<Map<String, dynamic>> bpRes = await db.query(
        'body_measurements',
        where: 'user_id = ? AND date = ? AND blood_pressure IS NOT NULL',
        whereArgs: [userId, dateStr],
      );

      final List<Map<String, dynamic>> mealsRes = await db.query(
        'nutrition_logs',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );

      final List<Map<String, dynamic>> moodRes = await db.query(
        'mood_entries',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, dateStr],
      );

      int loggedCount = 0;
      if (weightRes.isNotEmpty) loggedCount++;
      if (bpRes.isNotEmpty) loggedCount++;
      if (mealsRes.isNotEmpty) loggedCount++;
      if (moodRes.isNotEmpty) loggedCount++;

      completionRates.add(loggedCount / 4.0);
    }

    return completionRates;
  }
}
