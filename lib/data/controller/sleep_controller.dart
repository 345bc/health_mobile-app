import 'package:dio/dio.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/sleep_log.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/sleep_service.dart';

class SleepController {
  final DatabaseHelper _db;
  final SleepService _sleepService;

  SleepController({
    DatabaseHelper? db,
    SleepService? sleepService,
  })  : _db = db ?? DatabaseHelper(),
        _sleepService = sleepService ?? SleepService(ApiService());

  Future<SleepLog?> getLastSleep(int userId) => _db.getLastSleep(userId);

  Future<List<SleepLog>> getRecentSleeps(int userId, {int days = 7}) =>
      _db.getRecentSleeps(userId, days: days);

  /// Ghi nhận giấc ngủ từ giờ bắt đầu và kết thúc (chuỗi HH:mm)
  Future<int> logSleep({
    required int userId,
    required String date,
    required String startTime,
    required String endTime,
    int? qualityScore,
  }) async {
    // Tính duration (phút)
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    int duration = end.difference(start).inMinutes;
    if (duration < 0) duration += 24 * 60; // qua đêm

    final int localId = await _db.insertSleep(SleepLog(
      userId: userId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      qualityScore: qualityScore,
    ));

    // Sync to server
    final response = await _sleepService.createSleep({
      'userId': userId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'qualityScore': qualityScore,
    });

    if (response == null) {
      throw DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Không thể kết nối đến máy chủ.');
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      final db = await _db.database;
      final Map<String, dynamic> body =
          response.data is Map<String, dynamic> ? response.data : {};
      final data = body['data'] ?? body;
      final serverId = data['id'];
      if (serverId != null) {
        // Update SQLite primary key to match backend server ID
        await db.delete(
          'sleeps',
          where: 'sleep_id = ? AND sleep_id != ?',
          whereArgs: [serverId, localId],
        );
        await db.update(
          'sleeps',
          {'sleep_id': serverId},
          where: 'sleep_id = ?',
          whereArgs: [localId],
        );
      }
    }

    return localId;
  }

  DateTime _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}
