class ChecklistItem {
  ChecklistItem({
    this.id,
    required this.trackerId,
    required this.title,
    required this.isCompleted,
    required this.date,
  });

  final int? id;
  final int trackerId;
  final String title;
  final bool isCompleted;
  final DateTime date;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tracker_id': trackerId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'date': date.toIso8601String().split('T').first,
    };
  }

  factory ChecklistItem.fromMap(Map<String, Object?> map) {
    return ChecklistItem(
      id: map['id'] as int?,
      trackerId: map['tracker_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
