import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/water_service.dart';
import 'package:frontend/services/notification_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}
class MockBatch extends Mock implements Batch {}
class MockWaterService extends Mock implements WaterService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockResponse extends Mock implements Response {}

void main() {
  late WaterController waterController;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late MockWaterService mockWaterService;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(ConflictAlgorithm.replace);
  });

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();
    mockWaterService = MockWaterService();
    mockNotificationService = MockNotificationService();

    waterController = WaterController.internal(
      dbHelper: mockDbHelper,
      waterService: mockWaterService,
      notificationService: mockNotificationService,
    );

    // Default setups
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
  });

  group('WaterController - logWater', () {
    test('nên lưu SQLite và đồng bộ lên server thành công (trả về server id)', () async {
      // Mock db insert for first call (without conflictAlgorithm)
      when(() => mockDatabase.insert('water_logs', {
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 250,
      })).thenAnswer((_) async => 10); // localId = 10

      // Mock db insert for second call (with conflictAlgorithm)
      when(() => mockDatabase.insert('water_logs', {
        'water_log_id': 99,
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 250,
      }, conflictAlgorithm: ConflictAlgorithm.replace)).thenAnswer((_) async => 99);

      // Mock server sync response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(201);
      when(() => mockResponse.data).thenReturn({
        'data': {'id': 99} // serverId = 99
      });
      when(() => mockWaterService.createWaterLog(any())).thenAnswer((_) async => mockResponse);

      // Mock deleting local log after sync
      when(() => mockDatabase.delete(
            'water_logs',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      // Execute
      final result = await waterController.logWater(
        userId: 1,
        date: '2026-06-06',
        amount: 250,
      );

      // Verify result is serverId
      expect(result, 99);

      // Verify db calls
      verify(() => mockDatabase.insert('water_logs', {
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 250,
      })).called(1);

      verify(() => mockWaterService.createWaterLog({
        'userId': 1,
        'date': '2026-06-06',
        'amount': 250,
      })).called(1);

      verify(() => mockDatabase.delete(
            'water_logs',
            where: 'water_log_id = ?',
            whereArgs: [10],
          )).called(1);

      verify(() => mockDatabase.insert('water_logs', {
        'water_log_id': 99,
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 250,
      }, conflictAlgorithm: ConflictAlgorithm.replace)).called(1);
    });

    test('nên lưu SQLite cục bộ và ném ngoại lệ khi đồng bộ server thất bại', () async {
      // Mock db insert
      when(() => mockDatabase.insert('water_logs', {
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 500,
      })).thenAnswer((_) async => 12); // localId = 12

      // Mock server sync failure
      when(() => mockWaterService.createWaterLog(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      // Execute & Verify exception is thrown
      try {
        await waterController.logWater(
          userId: 1,
          date: '2026-06-06',
          amount: 500,
        );
        fail("Nên ném ngoại lệ DioException");
      } catch (e) {
        expect(e, isA<DioException>());
      }

      // Verify db insert was called (meaning it was saved offline/locally)
      verify(() => mockDatabase.insert('water_logs', {
        'user_id': 1,
        'date': '2026-06-06',
        'amount': 500,
      })).called(1);

      // Verify database delete/update not called
      verifyNever(() => mockDatabase.delete(
            'water_logs',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ));
    });
  });

  group('WaterController - deleteWaterLog', () {
    test('nên xóa log ở SQLite và gửi lệnh xóa lên server', () async {
      when(() => mockDatabase.delete(
            'water_logs',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockWaterService.deleteWaterLog(any())).thenAnswer((_) async => mockResponse);

      await waterController.deleteWaterLog(100);

      verify(() => mockDatabase.delete(
            'water_logs',
            where: 'water_log_id = ?',
            whereArgs: [100],
          )).called(1);

      verify(() => mockWaterService.deleteWaterLog(100)).called(1);
    });
  });

  group('WaterController - saveReminderSetting', () {
    test('nên lưu reminder và đặt báo thức hàng ngày khi isEnabled là true', () async {
      when(() => mockDbHelper.saveReminder(any(), any(), any(), any()))
          .thenAnswer((_) async => 1);

      when(() => mockNotificationService.scheduleDailyNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          )).thenAnswer((_) async {});

      when(() => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      await waterController.saveReminderSetting(
        userId: 1,
        type: 'water',
        time: '07:30',
        isEnabled: true,
      );

      verify(() => mockDbHelper.saveReminder(1, 'water', '07:30', true)).called(1);
      verify(() => mockNotificationService.scheduleDailyNotification(
            id: 104,
            title: 'Nhắc nhở: Uống nước',
            body: 'Uống nước thôi nào! Hãy uống một cốc nước để thanh lọc cơ thể nhé.',
            hour: 7,
            minute: 30,
          )).called(1);
      verify(() => mockNotificationService.showNotification(
            id: 1104,
            title: '🔔 Đã kích hoạt nhắc nhở thành công',
            body: 'Hệ thống sẽ thông báo nhắc nhở 07:30 hàng ngày!',
          )).called(1);
    });

    test('nên lưu reminder và hủy báo thức khi isEnabled là false', () async {
      when(() => mockDbHelper.saveReminder(any(), any(), any(), any()))
          .thenAnswer((_) async => 1);

      when(() => mockNotificationService.cancelNotification(any()))
          .thenAnswer((_) async {});

      await waterController.saveReminderSetting(
        userId: 1,
        type: 'water',
        time: '07:30',
        isEnabled: false,
      );

      verify(() => mockDbHelper.saveReminder(1, 'water', '07:30', false)).called(1);
      verify(() => mockNotificationService.cancelNotification(104)).called(1);
      verifyNever(() => mockNotificationService.scheduleDailyNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ));
    });
  });
}
