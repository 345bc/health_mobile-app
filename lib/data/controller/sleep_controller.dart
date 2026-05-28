import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/sleep_log.dart';

class SleepController {
  final DatabaseHelper _db = DatabaseHelper();

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
  }) {
    // Tính duration (phút)
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    int duration = end.difference(start).inMinutes;
    if (duration < 0) duration += 24 * 60; // qua đêm

    return _db.insertSleep(SleepLog(
      userId: userId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      qualityScore: qualityScore,
    ));
  }

  DateTime _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}
