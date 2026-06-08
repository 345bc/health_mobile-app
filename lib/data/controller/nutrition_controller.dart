import 'package:dio/dio.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/meal.dart';
import 'package:frontend/services/nutrition_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:sqflite/sqflite.dart';

class NutritionController {
  final DatabaseHelper _dbHelper;
  final NutritionService _nutritionService;

  NutritionController({
    DatabaseHelper? dbHelper,
    NutritionService? nutritionService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _nutritionService = nutritionService ?? NutritionService(ApiService());

  /// Log a meal locally and attempt to sync to the server
  Future<void> addMeal({
    required int userId,
    required String date,
    required String mealType,
    required String foodName,
    required int calories,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
  }) async {
    // 1. Save locally to SQLite first
    final db = await _dbHelper.database;
    
    final localFoodId = await db.insert('foods', {
      'name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    });

    final localLogId = await db.insert('nutrition_logs', {
      'user_id': userId,
      'date': date,
      'meal_type': mealType,
      'food_id': localFoodId,
      'quantity': 1.0,
    });

    // 2. Try to sync to the backend
    try {
      // Create Food on server
      final foodResponse = await _nutritionService.createFood({
        'name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      });

      if (foodResponse == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }

      if (foodResponse.statusCode == 200 || foodResponse.statusCode == 201) {
        final Map<String, dynamic> responseBody = foodResponse.data is Map<String, dynamic> 
            ? foodResponse.data 
            : {};
        final foodData = responseBody['data'] ?? responseBody;
        final serverFoodId = foodData['id'];

        if (serverFoodId != null) {
          // Create Nutrition Log on server
          final logResponse = await _nutritionService.createNutritionLog({
            'userId': userId,
            'date': date,
            'mealType': mealType,
            'foodId': serverFoodId,
            'quantity': 1.0,
          });

          if (logResponse == null) {
            throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
          }

          if (logResponse.statusCode == 200 || logResponse.statusCode == 201) {
            final Map<String, dynamic> logResponseBody = logResponse.data is Map<String, dynamic>
                ? logResponse.data
                : {};
            final logData = logResponseBody['data'] ?? logResponseBody;
            final serverLogId = logData['id'];

            if (serverLogId != null) {
              // Update local SQLite record with server IDs to keep them in sync
              await db.update(
                'nutrition_logs',
                {'log_id': serverLogId},
                where: 'log_id = ?',
                whereArgs: [localLogId],
              );
            }
          }
        }
      }
    } catch (e) {
      print("Không thể đồng bộ lên server (lưu cục bộ offline): $e");
      rethrow;
    }
  }

  /// Fetch meals for a given date, syncing from the server if online
  Future<List<Meal>> getMeals({required int userId, required String date}) async {
    // 1. Try to fetch from server first
    try {
      final response = await _nutritionService.getNutritionLogs(userId, date);
      if (response == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data is Map<String, dynamic>
            ? response.data
            : {};
        final dynamic rawList = responseBody['data'] ?? responseBody;
        
        if (rawList is List) {
          final db = await _dbHelper.database;
          final batch = db.batch();

          // Clear local logs for this date to overwrite with server truth
          batch.delete('nutrition_logs', where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);

          for (var logJson in rawList) {
            if (logJson is Map<String, dynamic>) {
              final foodJson = logJson['food'];
              if (foodJson is Map<String, dynamic>) {
                // Insert food locally
                batch.insert('foods', {
                  'food_id': foodJson['id'],
                  'name': foodJson['name'],
                  'calories': foodJson['calories'],
                  'protein': foodJson['protein'],
                  'carbs': foodJson['carbs'],
                  'fat': foodJson['fat'],
                }, conflictAlgorithm: ConflictAlgorithm.replace);

                // Insert log locally
                batch.insert('nutrition_logs', {
                  'log_id': logJson['id'],
                  'user_id': userId,
                  'date': date,
                  'meal_type': logJson['mealType'],
                  'food_id': foodJson['id'],
                  'quantity': logJson['quantity'],
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }

          await batch.commit(noResult: true);
        }
      }
    } catch (e) {
      print("Không thể tải từ server, sử dụng dữ liệu cục bộ: $e");
      rethrow;
    }

    // 2. Load from local database (acts as offline-first fallback or cache)
    return await _dbHelper.getMealsForDate(userId, date);
  }

  /// Delete a meal log
  Future<void> deleteMeal(int logId) async {
    // 1. Delete locally from SQLite
    await _dbHelper.deleteMeal(logId);

    // 2. Delete from server
    try {
      final response = await _nutritionService.deleteNutritionLog(logId);
      if (response == null) {
        throw DioException(requestOptions: RequestOptions(path: ''), message: 'Không thể kết nối đến máy chủ.');
      }
    } catch (e) {
      print("Lỗi khi đồng bộ xóa lên server: $e");
      rethrow;
    }
  }
}
