import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:frontend/data/controller/sleep_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/sleep_log.dart';
import 'package:frontend/services/sleep_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}
class MockSleepService extends Mock implements SleepService {}
class MockResponse extends Mock implements Response {}

void main() {
  late SleepController sleepController;
  late MockDatabaseHelper mockDb;
  late MockDatabase mockDatabase;
  late MockSleepService mockSleepService;

  setUpAll(() {
    registerFallbackValue(SleepLog(
      userId: 1,
      date: '2026-06-06',
      startTime: '22:00',
      endTime: '06:00',
      duration: 480,
    ));
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    mockSleepService = MockSleepService();
    sleepController = SleepController(db: mockDb, sleepService: mockSleepService);

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
  });

  test('getLastSleep nên lấy dữ liệu từ database helper', () async {
    final mockSleep = SleepLog(
      sleepId: 1,
      userId: 1,
      date: '2026-06-05',
      startTime: '23:00',
      endTime: '07:00',
      duration: 480,
    );
    when(() => mockDb.getLastSleep(1)).thenAnswer((_) async => mockSleep);

    final result = await sleepController.getLastSleep(1);
    expect(result, mockSleep);
    verify(() => mockDb.getLastSleep(1)).called(1);
  });

  test('logSleep nên tính toán thời lượng ngủ ban ngày chính xác', () async {
    when(() => mockDb.insertSleep(any())).thenAnswer((_) async => 1);

    final mockResponse = MockResponse();
    when(() => mockResponse.statusCode).thenReturn(201);
    when(() => mockResponse.data).thenReturn({
      'data': {'id': 100}
    });

    when(() => mockSleepService.createSleep(any())).thenAnswer((_) async => mockResponse);
    when(() => mockDatabase.delete(any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 0);
    when(() => mockDatabase.update(any(), any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 1);

    final result = await sleepController.logSleep(
      userId: 1,
      date: '2026-06-06',
      startTime: '13:00',
      endTime: '14:30',
      qualityScore: 80,
    );

    expect(result, 1);
    verify(() => mockDb.insertSleep(any(
          that: isA<SleepLog>()
              .having((s) => s.duration, 'duration', 90)
              .having((s) => s.startTime, 'startTime', '13:00')
              .having((s) => s.endTime, 'endTime', '14:30')
              .having((s) => s.qualityScore, 'qualityScore', 80),
        ))).called(1);
    verify(() => mockSleepService.createSleep(any())).called(1);
    verify(() => mockDatabase.delete('sleeps', where: 'sleep_id = ? AND sleep_id != ?', whereArgs: [100, 1])).called(1);
    verify(() => mockDatabase.update('sleeps', {'sleep_id': 100}, where: 'sleep_id = ?', whereArgs: [1])).called(1);
  });

  test('logSleep nên tính toán thời lượng ngủ qua đêm chính xác', () async {
    when(() => mockDb.insertSleep(any())).thenAnswer((_) async => 2);

    final mockResponse = MockResponse();
    when(() => mockResponse.statusCode).thenReturn(201);
    when(() => mockResponse.data).thenReturn({
      'data': {'id': 101}
    });

    when(() => mockSleepService.createSleep(any())).thenAnswer((_) async => mockResponse);
    when(() => mockDatabase.delete(any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 0);
    when(() => mockDatabase.update(any(), any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 1);

    final result = await sleepController.logSleep(
      userId: 1,
      date: '2026-06-06',
      startTime: '22:00',
      endTime: '06:00', // qua đêm (+8 tiếng)
      qualityScore: 90,
    );

    expect(result, 2);
    verify(() => mockDb.insertSleep(any(
          that: isA<SleepLog>()
              .having((s) => s.duration, 'duration', 480)
              .having((s) => s.startTime, 'startTime', '22:00')
              .having((s) => s.endTime, 'endTime', '06:00'),
        ))).called(1);
    verify(() => mockSleepService.createSleep(any())).called(1);
    verify(() => mockDatabase.delete('sleeps', where: 'sleep_id = ? AND sleep_id != ?', whereArgs: [101, 2])).called(1);
    verify(() => mockDatabase.update('sleeps', {'sleep_id': 101}, where: 'sleep_id = ?', whereArgs: [2])).called(1);
  });
}
