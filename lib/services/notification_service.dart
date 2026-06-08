import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static set instance(NotificationService mock) => _instance = mock;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Khởi tạo timezone - đặt múi giờ Việt Nam (tương tự baikt)
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {},
      );

      // Yêu cầu quyền thông báo (Android 13+) - tương tự baikt
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (e) {
          print('[NotificationService] Exact alarm permission: $e');
        }
      }

      _initialized = true;
      print('[NotificationService] Khởi tạo thành công.');
    } catch (e) {
      print('[NotificationService] init() lỗi: $e');
    }
  }

  /// Hiển thị thông báo ngay lập tức
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'health_app_updates',
        'Cập nhật sức khỏe',
        channelDescription:
            'Thông báo khi người dùng cập nhật hồ sơ cá nhân hoặc chỉ số sức khỏe',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      print('[NotificationService] showNotification() lỗi: $e');
    }
  }

  /// Lên lịch thông báo hàng ngày - tương tự baikt: thử exact trước, fallback sang inexact
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Nhắc nhở sức khỏe hàng ngày',
          channelDescription:
              'Nhắc nhở theo dõi sinh hiệu, hoạt động, giấc ngủ, dinh dưỡng, nước uống',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Thử exact alarm trước (tương tự baikt)
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('[NotificationService] Đã lên lịch EXACT cho id=$id lúc $hour:$minute');
      } catch (e) {
        // Fallback sang inexact nếu không có quyền exact alarm (tương tự baikt)
        print('[NotificationService] Fallback sang inexact do: $e');
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('[NotificationService] Đã lên lịch INEXACT cho id=$id lúc $hour:$minute');
      }
    } catch (e) {
      print('[NotificationService] scheduleDailyNotification() lỗi: $e');
      rethrow;
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Hủy thông báo theo ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      print('[NotificationService] cancelNotification() lỗi: $e');
    }
  }

  /// Hủy tất cả thông báo
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('[NotificationService] cancelAllNotifications() lỗi: $e');
    }
  }
}
