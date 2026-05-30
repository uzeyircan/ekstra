class ShiftTemplate {
  const ShiftTemplate({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.isEnabled,
  });

  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final int color;
  final bool isEnabled;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'isEnabled': isEnabled,
    };
  }

  factory ShiftTemplate.fromJson(Map<dynamic, dynamic> json) {
    return ShiftTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      color: json['color'] as int,
      isEnabled: (json['isEnabled'] as bool?) ?? true,
    );
  }
}
