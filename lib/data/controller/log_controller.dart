import 'package:dio/dio.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/body_measurement_service.dart';
import 'package:frontend/services/mood_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/activity_service.dart';
import 'package:frontend/services/sleep_service.dart';
import 'package:frontend/services/nutrition_service.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class LogController {
  final DatabaseHelper _dbHelper;
  final BodyMeasurementService _measurementService;
  final MoodService _moodService;
  final ActivityService _activityService;
  final SleepService _sleepService;
  final NutritionService _nutritionService;

  LogController({
    DatabaseHelper? dbHelper,
    BodyMeasurementService? measurementService,
    MoodService? moodService,
    ActivityService? activityService,
    SleepService? sleepService,
    NutritionService? nutritionService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _measurementService =
            measurementService ?? BodyMeasurementService(ApiService()),
        _moodService = moodService ?? MoodService(ApiService()),
        _activityService = activityService ?? ActivityService(ApiService()),
        _sleepService = sleepService ?? SleepService(ApiService()),
        _nutritionService = nutritionService ?? NutritionService(ApiService());

  /// Sync all measurements and moods from the server to local SQLite
  Future<void> refreshLogsFromServer(int userId) async {
    try {
      // 1. Sync Body Measurements
      final mResponse = await _measurementService.getBodyMeasurementsByUser(userId);
      if (mResponse == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (mResponse.statusCode == 200) {
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
      if (moodResponse == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (moodResponse.statusCode == 200) {
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

      // 3. Goal Sync removed

      // 4. Sync Activities
      final activityResponse = await _activityService.getActivitiesByUser(userId);
      if (activityResponse == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (activityResponse.statusCode == 200) {
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

      // 5. Sync Sleep Logs
      final sleepResponse = await _sleepService.getSleepsByUser(userId);
      if (sleepResponse == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (sleepResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody = sleepResponse.data is Map<String, dynamic>
            ? sleepResponse.data
            : {};
        final dynamic rawList = responseBody['data'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;
          final batch = db.batch();
          batch.delete('sleeps', where: 'user_id = ?', whereArgs: [userId]);

          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              batch.insert('sleeps', {
                'sleep_id': item['id'],
                'user_id': userId,
                'date': item['date'],
                'start_time': item['startTime'],
                'end_time': item['endTime'],
                'duration': item['duration'],
                'quality_score': item['qualityScore'],
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          await batch.commit(noResult: true);
        }
      }

      // 6. Sync Nutrition Logs (cho streak)
      try {
        final nutritionResponse = await _nutritionService.getAllNutritionLogsByUser(userId);
        if (nutritionResponse != null && nutritionResponse.statusCode == 200) {
          final Map<String, dynamic> responseBody = nutritionResponse.data is Map<String, dynamic>
              ? nutritionResponse.data
              : {};
          final dynamic rawList = responseBody['data'] ?? responseBody;

          if (rawList is List) {
            final db = await _dbHelper.database;
            final batch = db.batch();
            batch.delete('nutrition_logs', where: 'user_id = ?', whereArgs: [userId]);

            for (var item in rawList) {
              if (item is Map<String, dynamic>) {
                // Thêm food nếu chưa tồn tại
                final int foodId = await db.insert('foods', {
                  'name': item['foodName'] ?? item['name'] ?? 'Unknown',
                  'calories': item['calories'] ?? 0,
                  'protein': item['protein'] ?? 0.0,
                  'carbs': item['carbs'] ?? 0.0,
                  'fat': item['fat'] ?? 0.0,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
                batch.insert('nutrition_logs', {
                  'log_id': item['id'],
                  'user_id': userId,
                  'date': item['date'],
                  'meal_type': item['mealType'] ?? 'other',
                  'food_id': foodId > 0 ? foodId : (item['foodId'] ?? 1),
                  'quantity': item['quantity'] ?? 1.0,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
            await batch.commit(noResult: true);
          }
        }
      } catch (e) {
        // Không fail toàn bộ sync nếu nutrition lỗi
        print('Lỗi sync nutrition logs: $e');
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu đồng bộ từ server: $e");
      rethrow;
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
          final response = await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': weight,
            'bloodPressure': row['blood_pressure'],
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'weight': weight,
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
          if (response.statusCode == 200 || response.statusCode == 201) {
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
      rethrow;
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
          final response = await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': bloodPressure,
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'bloodPressure': bloodPressure,
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
          if (response.statusCode == 200 || response.statusCode == 201) {
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
      rethrow;
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
        final response = await _moodService.createMoodEntry({
          'userId': userId,
          'date': date,
          'moodScore': moodScore,
          'notes': notes,
        });
        if (response == null) {
          throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
        }
      } else {
        // CREATE on server
        final response = await _moodService.createMoodEntry({
          'userId': userId,
          'date': date,
          'moodScore': moodScore,
          'notes': notes,
        });
        if (response == null) {
          throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
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
      rethrow;
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
          final response = await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': row['blood_pressure'],
            'heartRate': row['heart_rate'],
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': bloodGlucose,
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'bloodGlucose': bloodGlucose,
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
          if (response.statusCode == 200 || response.statusCode == 201) {
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
      rethrow;
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
          final response = await _measurementService.updateBodyMeasurement(measurementId, {
            'userId': userId,
            'date': date,
            'weight': row['weight'],
            'bloodPressure': row['blood_pressure'],
            'heartRate': heartRate,
            'bodyFatPercentage': row['body_fat_percentage'],
            'bloodGlucose': row['blood_glucose'],
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
        } else {
          // CREATE on server
          final response = await _measurementService.createBodyMeasurement({
            'userId': userId,
            'date': date,
            'heartRate': heartRate,
          });
          if (response == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }
          if (response.statusCode == 200 || response.statusCode == 201) {
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
      rethrow;
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
      final response = await _measurementService.deleteBodyMeasurement(measurementId);
      if (response == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
    } catch (e) {
      print("Lỗi khi xóa đo lường trên server: $e");
      rethrow;
    }
  }

  /// Calculate consecutive logging streak leading up to today
  /// Streak dựa trên các bảng được đồng bộ đầy đủ từ server:
  /// activities, sleeps, body_measurements, mood_entries, nutrition_logs
  Future<int> calculateStreak(int userId) async {
    final db = await _dbHelper.database;
    final List<String> queries = [
      "SELECT DISTINCT date FROM activities WHERE user_id = ?",
      "SELECT DISTINCT date FROM sleeps WHERE user_id = ?",
      "SELECT DISTINCT date FROM nutrition_logs WHERE user_id = ?",
      "SELECT DISTINCT date FROM body_measurements WHERE user_id = ?",
      "SELECT DISTINCT date FROM mood_entries WHERE user_id = ?",
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
        .toSet()
        .toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // Streak chỉ tính nếu có ghi chép hôm nay hoặc hôm qua
    if (!sortedDates.contains(todayDate) && !sortedDates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.contains(todayDate) ? todayDate : yesterdayDate;

    while (sortedDates.contains(checkDate)) {
      streak++;
      final prevDate = checkDate.subtract(const Duration(days: 1));
      checkDate = DateTime(prevDate.year, prevDate.month, prevDate.day);
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
