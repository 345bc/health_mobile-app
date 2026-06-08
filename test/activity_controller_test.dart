import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:frontend/data/controller/activity_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/activity.dart';
import 'package:frontend/services/activity_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}
class MockActivityService extends Mock implements ActivityService {}
class MockResponse extends Mock implements Response {}

void main() {
  late ActivityController activityController;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late MockActivityService mockActivityService;

  setUpAll(() {
    registerFallbackValue(Activity(
      userId: 1,
      date: '2026-06-06',
      steps: 0,
    ));
  });

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    mockActivityService = MockActivityService();

    activityController = ActivityController(
      db: mockDbHelper,
      activityService: mockActivityService,
    );

    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
  });

  final testActivity = Activity(
    activityId: 10,
    userId: 1,
    date: '2026-06-06',
    steps: 5000,
    distance: 3.5,
    caloriesBurned: 200,
    source: 'manual',
  );

  test('getTodayActivity nên trả về đúng dữ liệu từ database helper', () async {
    when(() => mockDbHelper.getTodayActivity(1)).thenAnswer((_) async => testActivity);
    final result = await activityController.getTodayActivity(1);
    expect(result, testActivity);
    verify(() => mockDbHelper.getTodayActivity(1)).called(1);
  });

  test('getRecentActivities nên trả về danh sách từ database helper', () async {
    when(() => mockDbHelper.getRecentActivities(1, days: 5)).thenAnswer((_) async => [testActivity]);
    final result = await activityController.getRecentActivities(1, days: 5);
    expect(result.length, 1);
    verify(() => mockDbHelper.getRecentActivities(1, days: 5)).called(1);
  });

  group('upsertTodayActivity', () {
    test('nên cập nhật server khi ĐÃ CÓ hoạt động hiện tại trong ngày', () async {
      when(() => mockDbHelper.getTodayActivity(1)).thenAnswer((_) async => testActivity);
      when(() => mockDbHelper.upsertTodayActivity(any())).thenAnswer((_) async => 10);
      
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockActivityService.updateActivity(any(), any())).thenAnswer((_) async => mockResponse);

      final result = await activityController.upsertTodayActivity(
        userId: 1,
        steps: 8000,
        distance: 5.0,
        caloriesBurned: 300,
      );

      expect(result, 10);
      verify(() => mockDbHelper.upsertTodayActivity(any())).called(1);
      verify(() => mockActivityService.updateActivity(10, {
        'userId': 1,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'steps': 8000,
        'distance': 5.0,
        'caloriesBurned': 300,
        'source': 'manual',
      })).called(1);
    });

    test('nên tạo mới trên server và cập nhật SQLite ID khi CHƯA CÓ hoạt động trong ngày', () async {
      when(() => mockDbHelper.getTodayActivity(1)).thenAnswer((_) async => null);
      when(() => mockDbHelper.upsertTodayActivity(any())).thenAnswer((_) async => 5); // localId = 5

      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(201);
      when(() => mockResponse.data).thenReturn({
        'id': 100 // serverId = 100
      });
      when(() => mockActivityService.createActivity(any())).thenAnswer((_) async => mockResponse);

      when(() => mockDatabase.delete(any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(any(), any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);

      final result = await activityController.upsertTodayActivity(
        userId: 1,
        steps: 6000,
        distance: 4.0,
        caloriesBurned: 250,
      );

      expect(result, 5);
      verify(() => mockDbHelper.upsertTodayActivity(any())).called(1);
      verify(() => mockActivityService.createActivity({
        'userId': 1,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'steps': 6000,
        'distance': 4.0,
        'caloriesBurned': 250,
        'source': 'manual',
      })).called(1);

      verify(() => mockDatabase.delete(
            'activities',
            where: 'activity_id = ? AND activity_id != ?',
            whereArgs: [100, 5],
          )).called(1);

      verify(() => mockDatabase.update(
            'activities',
            {'activity_id': 100},
            where: 'activity_id = ?',
            whereArgs: [5],
          )).called(1);
    });
  });
}
