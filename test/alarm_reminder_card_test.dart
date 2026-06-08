import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/widgets/alarm_reminder_card.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/services/sound_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockWaterController extends Mock implements WaterController {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockDatabaseHelper mockDatabaseHelper;
  late MockWaterController mockWaterController;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockWaterController = MockWaterController();
    mockNotificationService = MockNotificationService();
    
    // Inject mock singletons
    DatabaseHelper.instance = mockDatabaseHelper;
    WaterController.instance = mockWaterController;
    NotificationService.instance = mockNotificationService;

    // Disable sound and stub notification init
    SoundService.enableSound = false;
    when(() => mockNotificationService.init()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: AlarmReminderCard(
          userId: 1,
          type: 'water',
        ),
      ),
    );
  }

  group('AlarmReminderCard Widget Test', () {
    testWidgets('nên hiển thị đúng trạng thái ban đầu khi ĐÃ lưu nhắc nhở và bật (isEnabled: true)', (WidgetTester tester) async {
      // Stub database response
      when(() => mockDatabaseHelper.getReminder(1, 'water'))
          .thenAnswer((_) async => {'time': '09:15', 'is_enabled': 1});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify header components
      expect(find.text('Nhắc nhở hàng ngày'), findsOneWidget);
      expect(find.text('Thông báo đẩy nhắc ghi chép'), findsOneWidget);

      // Verify time is displayed
      expect(find.text('09:15'), findsOneWidget);
      expect(find.text('Thời gian nhận thông báo:'), findsOneWidget);

      // Verify switch is ON
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('nên hiển thị Switch tắt và ẩn thời gian khi nhắc nhở tắt (isEnabled: false)', (WidgetTester tester) async {
      // Stub database response
      when(() => mockDatabaseHelper.getReminder(1, 'water'))
          .thenAnswer((_) async => {'time': '08:00', 'is_enabled': 0});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify time is hidden
      expect(find.text('Thời gian nhận thông báo:'), findsNothing);
      expect(find.text('08:00'), findsNothing);

      // Verify switch is OFF
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('nên gọi saveReminderSetting ở WaterController khi người dùng bật Switch', (WidgetTester tester) async {
      // Stub database load
      when(() => mockDatabaseHelper.getReminder(1, 'water'))
          .thenAnswer((_) async => {'time': '08:00', 'is_enabled': 0});

      // Stub controller save
      when(() => mockWaterController.saveReminderSetting(
            userId: any(named: 'userId'),
            type: any(named: 'type'),
            time: any(named: 'time'),
            isEnabled: any(named: 'isEnabled'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify switch is OFF initially
      final switchFinder = find.byType(Switch);
      final Switch switchWidgetBefore = tester.widget<Switch>(switchFinder);
      expect(switchWidgetBefore.value, isFalse);

      // Toggle switch to ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify saveReminderSetting is triggered on controller
      verify(() => mockWaterController.saveReminderSetting(
            userId: 1,
            type: 'water',
            time: '08:00',
            isEnabled: true,
          )).called(1);
    });
  });
}
