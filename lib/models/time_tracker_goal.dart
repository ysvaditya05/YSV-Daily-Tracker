class TimeTrackerGoal {
  const TimeTrackerGoal({
    this.id,
    required this.trackerId,
    required this.dailyGoalSeconds,
    required this.effectiveDate,
  });

  final int? id;
  final int trackerId;
  final int dailyGoalSeconds;
  final DateTime effectiveDate;

  factory TimeTrackerGoal.fromMap(Map<String, Object?> map) {
    return TimeTrackerGoal(
      id: map['id'] as int,
      trackerId: map['tracker_id'] as int,
      dailyGoalSeconds: map['daily_goal_seconds'] as int,
      effectiveDate: DateTime.parse(map['effective_date'] as String),
    );
  }
}
