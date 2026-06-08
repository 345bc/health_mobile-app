import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:frontend/data/controller/nutrition_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/nutrition_service.dart';
import 'package:frontend/data/models/meal.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}
class MockBatch extends Mock implements Batch {}
class MockNutritionService extends Mock implements NutritionService {}
class MockResponse extends Mock implements Response {}

void main() {
  late NutritionController nutritionController;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late MockNutritionService mockNutritionService;

  setUpAll(() {
    registerFallbackValue(ConflictAlgorithm.replace);
  });

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();
    mockNutritionService = MockNutritionService();

    nutritionController = NutritionController(
      dbHelper: mockDbHelper,
      nutritionService: mockNutritionService,
    );

    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
  });

  group('addMeal', () {
    test('nên lưu SQLite và đồng bộ API thành công', () async {
      // Mock SQLite inserts
      when(() => mockDatabase.insert('foods', any())).thenAnswer((_) async => 10);
      when(() => mockDatabase.insert('nutrition_logs', any())).thenAnswer((_) async => 5);

      // Mock Nutrition Service API Responses
      final mockFoodResponse = MockResponse();
      when(() => mockFoodResponse.statusCode).thenReturn(201);
      when(() => mockFoodResponse.data).thenReturn({'data': {'id': 200}});
      when(() => mockNutritionService.createFood(any())).thenAnswer((_) async => mockFoodResponse);

      final mockLogResponse = MockResponse();
      when(() => mockLogResponse.statusCode).thenReturn(201);
      when(() => mockLogResponse.data).thenReturn({'data': {'id': 500}});
      when(() => mockNutritionService.createNutritionLog(any())).thenAnswer((_) async => mockLogResponse);

      // Mock database update
      when(() => mockDatabase.update(any(), any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);

      await nutritionController.addMeal(
        userId: 1,
        date: '2026-06-06',
        mealType: 'Breakfast',
        foodName: 'Apple',
        calories: 95,
      );

      verify(() => mockDatabase.insert('foods', {
        'name': 'Apple',
        'calories': 95,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
      })).called(1);

      verify(() => mockDatabase.insert('nutrition_logs', {
        'user_id': 1,
        'date': '2026-06-06',
        'meal_type': 'Breakfast',
        'food_id': 10,
        'quantity': 1.0,
      })).called(1);

      verify(() => mockNutritionService.createFood({
        'name': 'Apple',
        'calories': 95,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
      })).called(1);

      verify(() => mockNutritionService.createNutritionLog({
        'userId': 1,
        'date': '2026-06-06',
        'mealType': 'Breakfast',
        'foodId': 200,
        'quantity': 1.0,
      })).called(1);

      verify(() => mockDatabase.update(
            'nutrition_logs',
            {'log_id': 500},
            where: 'log_id = ?',
            whereArgs: [5],
          )).called(1);
    });
  });

  group('getMeals', () {
    test('nên tải từ server và lưu SQLite local', () async {
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.data).thenReturn({
        'data': [
          {
            'id': 500,
            'mealType': 'Lunch',
            'quantity': 1.0,
            'food': {
              'id': 200,
              'name': 'Salad',
              'calories': 150,
              'protein': 2.0,
              'carbs': 10.0,
              'fat': 8.0,
            }
          }
        ]
      });
      when(() => mockNutritionService.getNutritionLogs(1, '2026-06-06'))
          .thenAnswer((_) async => mockResponse);

      when(() => mockBatch.commit(noResult: any(named: 'noResult'))).thenAnswer((_) async => []);
      
      final mockMeal = Meal(
        logId: 500,
        userId: 1,
        date: '2026-06-06',
        mealType: 'Lunch',
        foodName: 'Salad',
        calories: 150,
      );
      when(() => mockDbHelper.getMealsForDate(1, '2026-06-06')).thenAnswer((_) async => [mockMeal]);

      final meals = await nutritionController.getMeals(userId: 1, date: '2026-06-06');
      expect(meals.length, 1);
      expect(meals.first.foodName, 'Salad');

      verify(() => mockBatch.delete('nutrition_logs', where: 'user_id = ? AND date = ?', whereArgs: [1, '2026-06-06']))
          .called(1);
      verify(() => mockBatch.insert('foods', {
        'food_id': 200,
        'name': 'Salad',
        'calories': 150,
        'protein': 2.0,
        'carbs': 10.0,
        'fat': 8.0,
      }, conflictAlgorithm: ConflictAlgorithm.replace)).called(1);
    });
  });

  group('deleteMeal', () {
    test('nên xóa SQLite local và gọi API xóa trên server', () async {
      when(() => mockDbHelper.deleteMeal(100)).thenAnswer((_) async => 1);
      
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockNutritionService.deleteNutritionLog(100))
          .thenAnswer((_) async => mockResponse);

      await nutritionController.deleteMeal(100);

      verify(() => mockDbHelper.deleteMeal(100)).called(1);
      verify(() => mockNutritionService.deleteNutritionLog(100)).called(1);
    });
  });
}
