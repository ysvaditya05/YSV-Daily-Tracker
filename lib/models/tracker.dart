class Tracker {
  const Tracker({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String type;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tracker.fromMap(Map<String, Object?> map) {
    return Tracker(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
