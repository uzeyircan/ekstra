import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/day_status/domain/day_status_type.dart';

class DayStatus {
  const DayStatus({
    required this.id,
    required this.date,
    required this.type,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final DayStatusType type;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayStatus copyWith({
    String? id,
    DateTime? date,
    DayStatusType? type,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayStatus(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateKey.fromDate(date),
      'type': type.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DayStatus.fromJson(Map<dynamic, dynamic> json) {
    return DayStatus(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: DayStatusType.fromName(json['type'] as String),
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
