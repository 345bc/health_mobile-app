class SleepLog {
  final int? sleepId;
  final int userId;
  final String date;
  final String startTime;
  final String endTime;
  final int? duration; // phút
  final int? qualityScore; // 1–5

  SleepLog({
    this.sleepId,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.duration,
    this.qualityScore,
  });

  Map<String, dynamic> toMap() {
    return {
      if (sleepId != null) 'sleep_id': sleepId,
      'user_id': userId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'quality_score': qualityScore,
    };
  }

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      sleepId: map['sleep_id'],
      userId: map['user_id'],
      date: map['date'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      duration: map['duration'],
      qualityScore: map['quality_score'],
    );
  }

  /// Trả về chuỗi dạng "7h 20m"
  String get durationFormatted {
    if (duration == null) return '--';
    final h = duration! ~/ 60;
    final m = duration! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
