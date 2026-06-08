import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/services/water_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/services/reminder_service.dart';
import 'package:sqflite/sqflite.dart';

class WaterController {
  static WaterController _instance = WaterController.internal();
  factory WaterController() => _instance;

  WaterController.internal({
    DatabaseHelper? dbHelper,
    WaterService? waterService,
    NotificationService? notificationService,
    ReminderService? reminderService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper(),
       _waterService = waterService ?? WaterService(ApiService()),
       _notificationService = notificationService ?? NotificationService(),
       _reminderService = reminderService ?? ReminderService(ApiService());

  static set instance(WaterController mock) => _instance = mock;

  final DatabaseHelper _dbHelper;
  final WaterService _waterService;
  final NotificationService _notificationService;
  final ReminderService _reminderService;

  static const Map<String, Map<String, dynamic>> reminderConfigs = {
    'vitals': {
      'id': 100,
      'title': 'Nhắc nhở: Sinh hiệu',
      'body':
          'Đã đến giờ đo huyết áp, nhịp tim và đường huyết hôm nay rồi. Hãy ghi lại nhé!',
    },
    'activity': {
      'id': 101,
      'title': 'Nhắc nhở: Hoạt động',
      'body':
          'Đừng quên ghi nhận số bước chân và thời gian vận động của bạn hôm nay!',
    },
    'sleep': {
      'id': 102,
      'title': 'Nhắc nhở: Giấc ngủ',
      'body':
          'Hãy cập nhật giờ ngủ và thức giấc hôm nay để theo dõi chất lượng giấc ngủ nhé.',
    },
    'nutrition': {
      'id': 103,
      'title': 'Nhắc nhở: Dinh dưỡng',
      'body':
          'Hãy ghi chép lại các món ăn bạn đã dùng hôm nay để kiểm soát lượng calo.',
    },
    'water': {
      'id': 104,
      'title': 'Nhắc nhở: Uống nước',
      'body':
          'Uống nước thôi nào! Hãy uống một cốc nước để thanh lọc cơ thể nhé.',
    },
  };

  Future<void> refreshWaterLogsFromServer(int userId) async {
    // Bước 1: Gọi API — chỉ catch lỗi network/timeout ở đây
    final response = await _waterService.getWaterLogsByUser(userId);
    if (response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Không thể kết nối đến máy chủ.',
      );
    }

    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            response.data is Map<String, dynamic> ? response.data : {};
        final dynamic rawList =
            responseBody['data'] ?? responseBody['result'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;

          await db.transaction((txn) async {
            await txn.delete(
              'water_logs',
              where: 'user_id = ?',
              whereArgs: [userId],
            );

            for (var item in rawList) {
              if (item is Map<String, dynamic>) {
                await txn.insert('water_logs', {
                  'water_log_id': item['id'],
                  'user_id': userId,
                  'date': item['date'],
                  'amount': item['amount'],
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lưu water logs vào DB: $e');
    }
  }

  /// Ghi nhận lượng nước uống (Lưu SQLite + Đồng bộ lên Server)
  Future<int> logWater({
    required int userId,
    required String date,
    required int amount,
  }) async {
    final db = await _dbHelper.database;

    // 1. Lưu SQLite trước
    final int localId = await db.insert('water_logs', {
      'user_id': userId,
      'date': date,
      'amount': amount,
    });

    // 2. Đồng bộ lên server
    final response = await _waterService.createWaterLog({
      'userId': userId,
      'date': date,
      'amount': amount,
    });

    if (response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Không thể kết nối đến máy chủ.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseBody =
          response.data is Map<String, dynamic> ? response.data : {};
      final dynamic data =
          responseBody['data'] ?? responseBody['result'] ?? responseBody;
      final int? serverId = data['id'];

      if (serverId != null) {
        // Xóa bản ghi local cũ để tránh trùng lặp
        await db.delete(
          'water_logs',
          where: 'water_log_id = ?',
          whereArgs: [localId],
        );
        // Chèn bản ghi mới với ID của Server
        await db.insert('water_logs', {
          'water_log_id': serverId,
          'user_id': userId,
          'date': date,
          'amount': amount,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return serverId;
      }
    }
    return localId;
  }

  /// Xóa nhật ký nước uống
  Future<void> deleteWaterLog(int waterLogId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'water_logs',
      where: 'water_log_id = ?',
      whereArgs: [waterLogId],
    );

    final response = await _waterService.deleteWaterLog(waterLogId);
    if (response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Không thể kết nối đến máy chủ.',
      );
    }
  }

  /// Thiết lập/Cập nhật nhắc nhở (Báo thức)
  Future<void> saveReminderSetting({
    required int userId,
    required String type,
    required String time, // Định dạng "HH:mm"
    required bool isEnabled,
  }) async {
    // 1. Lưu SQLite (luôn luôn thực hiện)
    await _dbHelper.saveReminder(userId, type, time, isEnabled);

    // 2. Đồng bộ lên server
    final response = await _reminderService.saveReminder({
      'userId': userId,
      'type': type,
      'time': time,
      'isEnabled': isEnabled,
    });

    if (response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Không thể kết nối đến máy chủ.',
      );
    }

    // 3. Thiết lập thông báo Local Notification
    final config = reminderConfigs[type.toLowerCase()];
    if (config == null) return;

    final int notificationId = config['id'] as int;
    final String title = config['title'] as String;
    final String body = config['body'] as String;

    if (isEnabled) {
      final parts = time.split(':');
      if (parts.length == 2) {
        final int hour = int.tryParse(parts[0]) ?? 8;
        final int minute = int.tryParse(parts[1]) ?? 0;

        await _notificationService.scheduleDailyNotification(
          id: notificationId,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
        );

        // Hiển thị thông báo ngay lập tức để xác nhận kích hoạt
        await _notificationService.showNotification(
          id: notificationId + 1000,
          title: '🔔 Đã kích hoạt nhắc nhở thành công',
          body: 'Hệ thống sẽ thông báo nhắc nhở $time hàng ngày!',
        );
      }
    } else {
      await _notificationService.cancelNotification(notificationId);
    }
  }

  /// Tải tất cả nhắc nhở từ server về SQLite và lên lịch thông báo cục bộ
  Future<void> refreshRemindersFromServer(int userId) async {
    final response = await _reminderService.getRemindersByUser(userId);
    if (response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Không thể kết nối đến máy chủ.',
      );
    }

    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            response.data is Map<String, dynamic> ? response.data : {};
        final dynamic rawList =
            responseBody['data'] ?? responseBody['result'] ?? responseBody;

        if (rawList is List) {
          final db = await _dbHelper.database;

          await db.transaction((txn) async {
            await txn.delete(
              'reminders',
              where: 'user_id = ?',
              whereArgs: [userId],
            );

            for (var item in rawList) {
              if (item is Map<String, dynamic>) {
                final String type = item['type'];
                final String time = item['time'];
                final bool isEnabled = item['isEnabled'] ?? false;
                final int enabledVal = isEnabled ? 1 : 0;

                await txn.insert('reminders', {
                  'user_id': userId,
                  'type': type,
                  'time': time,
                  'is_enabled': enabledVal,
                }, conflictAlgorithm: ConflictAlgorithm.replace);

                // Thiết lập thông báo cục bộ tương ứng
                final config = reminderConfigs[type.toLowerCase()];
                if (config != null) {
                  final int notificationId = config['id'] as int;
                  final String title = config['title'] as String;
                  final String body = config['body'] as String;

                  if (isEnabled) {
                    final parts = time.split(':');
                    if (parts.length == 2) {
                      final int hour = int.tryParse(parts[0]) ?? 8;
                      final int minute = int.tryParse(parts[1]) ?? 0;

                      await _notificationService.scheduleDailyNotification(
                        id: notificationId,
                        title: title,
                        body: body,
                        hour: hour,
                        minute: minute,
                      );
                    }
                  } else {
                    await _notificationService.cancelNotification(notificationId);
                  }
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lưu reminders vào DB: $e');
    }
  }
}
