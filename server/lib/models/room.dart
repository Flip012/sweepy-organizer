class Room {
  final String id;
  final String householdId;
  final String name;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.householdId,
    required this.name,
    this.icon = 'home',
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Room.fromRow(Map<String, dynamic> row) {
    return Room(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String? ?? 'home',
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'householdId': householdId,
        'name': name,
        'icon': icon,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };
}
