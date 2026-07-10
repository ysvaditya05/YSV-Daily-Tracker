class TimeSession {
  const TimeSession({
    this.id,
    required this.trackerId,
    required this.date,
    required this.duration,
    required this.isManual,
    this.startedAt,
    this.endedAt,
  });

  final int? id;
  final int trackerId;
  final DateTime date;
  final Duration duration;
  final bool isManual;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory TimeSession.fromMap(Map<String, Object?> map) {
    final startedAt = map['started_at'] as String?;
    final endedAt = map['ended_at'] as String?;

    return TimeSession(
      id: map['id'] as int,
      trackerId: map['tracker_id'] as int,
      date: DateTime.parse(map['session_date'] as String),
      duration: Duration(seconds: map['duration_seconds'] as int),
      isManual: (map['is_manual'] as int) == 1,
      startedAt: startedAt == null ? null : DateTime.parse(startedAt),
      endedAt: endedAt == null ? null : DateTime.parse(endedAt),
    );
  }
}
