class NumberTrackerSettings {
  const NumberTrackerSettings({
    this.id,
    required this.trackerId,
    required this.currentValue,
    required this.dailyGoal,
    required this.unit,
  });

  final int? id;
  final int trackerId;
  final double currentValue;
  final double? dailyGoal;
  final String unit;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tracker_id': trackerId,
      'current_value': currentValue,
      'daily_goal': dailyGoal,
      'unit': unit,
    };
  }

  factory NumberTrackerSettings.fromMap(Map<String, Object?> map) {
    return NumberTrackerSettings(
      id: map['id'] as int,
      trackerId: map['tracker_id'] as int,
      currentValue: (map['current_value'] as num).toDouble(),
      dailyGoal: (map['daily_goal'] as num?)?.toDouble(),
      unit: map['unit'] as String,
    );
  }
}
