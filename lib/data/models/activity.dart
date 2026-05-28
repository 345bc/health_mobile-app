class Activity {
  final int? activityId;
  final int userId;
  final String date;
  final int steps;
  final double distance;
  final int caloriesBurned;
  final String? source;

  Activity({
    this.activityId,
    required this.userId,
    required this.date,
    this.steps = 0,
    this.distance = 0.0,
    this.caloriesBurned = 0,
    this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      if (activityId != null) 'activity_id': activityId,
      'user_id': userId,
      'date': date,
      'steps': steps,
      'distance': distance,
      'calories_burned': caloriesBurned,
      'source': source,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      activityId: map['activity_id'],
      userId: map['user_id'],
      date: map['date'],
      steps: map['steps'] ?? 0,
      distance: map['distance'] != null ? (map['distance'] as num).toDouble() : 0.0,
      caloriesBurned: map['calories_burned'] ?? 0,
      source: map['source'],
    );
  }
}
