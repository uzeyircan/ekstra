import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';

class OvertimeEntry {
  const OvertimeEntry({
    required this.id,
    required this.date,
    required this.hours,
    required this.note,
    required this.overtimeType,
    required this.multiplier,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final double hours;
  final String note;
  final OvertimeType overtimeType;
  final double multiplier;
  final DateTime createdAt;
  final DateTime updatedAt;

  double earning(double hourlyRate) => hours * hourlyRate * multiplier;

  OvertimeEntry copyWith({
    String? id,
    DateTime? date,
    double? hours,
    String? note,
    OvertimeType? overtimeType,
    double? multiplier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OvertimeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      note: note ?? this.note,
      overtimeType: overtimeType ?? this.overtimeType,
      multiplier: multiplier ?? this.multiplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateKey.fromDate(date),
      'hours': hours,
      'note': note,
      'overtimeType': overtimeType.name,
      'multiplier': multiplier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OvertimeEntry.fromJson(Map<dynamic, dynamic> json) {
    return OvertimeEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      overtimeType: OvertimeType.fromName(json['overtimeType'] as String),
      multiplier: (json['multiplier'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
