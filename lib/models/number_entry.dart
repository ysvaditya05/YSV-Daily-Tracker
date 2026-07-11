class NumberEntry {
  const NumberEntry({
    this.id,
    required this.trackerId,
    required this.date,
    required this.value,
    required this.createdAt,
    this.description,
  });

  final int? id;
  final int trackerId;

  /// Day this entry belongs to.
  final DateTime date;

  /// Signed value.
  /// Positive = increment.
  /// Negative = decrement.
  final double value;

  /// Exact timestamp of the entry.
  final DateTime createdAt;

  /// Optional note, e.g. "Lunch", "Breakfast".
  final String? description;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tracker_id': trackerId,
      'entry_date': date.toIso8601String(),
      'value': value,
      'created_at': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory NumberEntry.fromMap(Map<String, Object?> map) {
    return NumberEntry(
      id: map['id'] as int,
      trackerId: map['tracker_id'] as int,
      date: DateTime.parse(map['entry_date'] as String),
      value: (map['value'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      description: map['description'] as String?,
    );
  }
}
