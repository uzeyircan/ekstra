import 'package:ekstra/core/services/date_key.dart';

class ShiftAssignment {
  const ShiftAssignment({
    required this.id,
    required this.date,
    required this.templateId,
    required this.templateName,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final String templateId;
  final String templateName;
  final String startTime;
  final String endTime;
  final int color;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateKey.fromDate(date),
      'templateId': templateId,
      'templateName': templateName,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShiftAssignment.fromJson(Map<dynamic, dynamic> json) {
    return ShiftAssignment(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      templateId: json['templateId'] as String,
      templateName: json['templateName'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      color: json['color'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
