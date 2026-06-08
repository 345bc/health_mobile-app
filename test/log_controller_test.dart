import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:frontend/data/controller/log_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/body_measurement_service.dart';
import 'package:frontend/services/mood_service.dart';
import 'package:frontend/services/activity_service.dart';
import 'package:frontend/services/sleep_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}
class MockBatch extends Mock implements Batch {}
class MockBodyMeasurementService extends Mock implements BodyMeasurementService {}
class MockMoodService extends Mock implements MoodService {}
class MockActivityService extends Mock implements ActivityService {}
class MockSleepService extends Mock implements SleepService {}
class MockResponse extends Mock implements Response {}

void main() {
  late LogController logController;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late MockBodyMeasurementService mockMeasurementService;
  late MockMoodService mockMoodService;
  late MockActivityService mockActivityService;
  late MockSleepService mockSleepService;

  setUpAll(() {
    registerFallbackValue(ConflictAlgorithm.replace);
  });

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();
    mockMeasurementService = MockBodyMeasurementService();
    mockMoodService = MockMoodService();
    mockActivityService = MockActivityService();
    mockSleepService = MockSleepService();

    logController = LogController(
      dbHelper: mockDbHelper,
      measurementService: mockMeasurementService,
      moodService: mockMoodService,
      activityService: mockActivityService,
      sleepService: mockSleepService,
    );

    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
  });

  group('refreshLogsFromServer', () {
    test('nên tải body measurements, mood logs, và sleep logs từ server rồi lưu SQLite', () async {
      // Mock Body Measurements Response
      final mockMResponse = MockResponse();
      when(() => mockMResponse.statusCode).thenReturn(200);
      when(() => mockMResponse.data).thenReturn({
        'data': [
          {
            'id': 10,
            'date': '2026-06-06',
            'weight': 70.5,
            'bodyFatPercentage': 15.2,
            'bloodPressure': '120/80',
            'bloodGlucose': 95.0,
            'heartRate': 72,
          }
        ]
      });
      when(() => mockMeasurementService.getBodyMeasurementsByUser(1))
          .thenAnswer((_) async => mockMResponse);

      // Mock Mood Response
      final mockMoodResponse = MockResponse();
      when(() => mockMoodResponse.statusCode).thenReturn(200);
      when(() => mockMoodResponse.data).thenReturn({
        'data': [
          {
            'id': 5,
            'date': '2026-06-06',
            'moodScore': 4,
            'notes': 'Vui vẻ',
          }
        ]
      });
      when(() => mockMoodService.getMoodEntriesByUser(1))
          .thenAnswer((_) async => mockMoodResponse);

      // Mock Activity Response (to make it complete)
      final mockActResponse = MockResponse();
      when(() => mockActResponse.statusCode).thenReturn(200);
      when(() => mockActResponse.data).thenReturn({'data': []});
      when(() => mockActivityService.getActivitiesByUser(1))
          .thenAnswer((_) async => mockActResponse);

      // Mock Sleep Response
      final mockSleepResponse = MockResponse();
      when(() => mockSleepResponse.statusCode).thenReturn(200);
      when(() => mockSleepResponse.data).thenReturn({
        'data': [
          {
            'id': 8,
            'date': '2026-06-06',
            'startTime': '23:00',
            'endTime': '07:00',
            'duration': 480,
            'qualityScore': 4,
          }
        ]
      });
      when(() => mockSleepService.getSleepsByUser(1))
          .thenAnswer((_) async => mockSleepResponse);

      // Mock Batch calls
      when(() => mockBatch.commit(noResult: any(named: 'noResult'))).thenAnswer((_) async => []);

      await logController.refreshLogsFromServer(1);

      // Verify Body Measurement batch write
      verify(() => mockBatch.delete('body_measurements', where: 'user_id = ?', whereArgs: [1])).called(1);
      verify(() => mockBatch.insert('body_measurements', {
        'measurement_id': 10,
        'user_id': 1,
        'date': '2026-06-06',
        'weight': 70.5,
        'body_fat_percentage': 15.2,
        'blood_pressure': '120/80',
        'blood_glucose': 95.0,
        'heart_rate': 72,
      }, conflictAlgorithm: ConflictAlgorithm.replace)).called(1);

      // Verify Mood batch write
      verify(() => mockBatch.delete('mood_entries', where: 'user_id = ?', whereArgs: [1])).called(1);
      verify(() => mockBatch.insert('mood_entries', {
        'mood_id': 5,
        'user_id': 1,
        'date': '2026-06-06',
        'mood_score': 4,
        'notes': 'Vui vẻ',
      }, conflictAlgorithm: ConflictAlgorithm.replace)).called(1);

      // Verify Sleep batch write
      verify(() => mockBatch.delete('sleeps', where: 'user_id = ?', whereArgs: [1])).called(1);
      verify(() => mockBatch.insert('sleeps', {
        'sleep_id': 8,
        'user_id': 1,
        'date': '2026-06-06',
        'start_time': '23:00',
        'end_time': '07:00',
        'duration': 480,
        'quality_score': 4,
      }, conflictAlgorithm: ConflictAlgorithm.replace)).called(1);
    });
  });
}
