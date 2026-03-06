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

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        householdId: json['householdId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'home',
        sortOrder: json['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'sortOrder': sortOrder,
      };

  /// Map icon string name to Material icon
  static const iconMap = <String, int>{
    'home': 0xe318,
    'kitchen': 0xe56a,
    'bathroom': 0xf1b5,
    'bedroom': 0xe91e,
    'living_room': 0xf09e,
    'dining_room': 0xe56c,
    'garage': 0xe57c,
    'garden': 0xef3b,
    'office': 0xe8b4,
    'laundry': 0xf1b6,
    'hallway': 0xe88a,
    'balcony': 0xe586,
  };
}
