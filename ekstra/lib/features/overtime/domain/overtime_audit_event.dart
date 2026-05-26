class OvertimeAuditEvent {
  const OvertimeAuditEvent({
    required this.id,
    required this.action,
    required this.entryId,
    required this.happenedAt,
    required this.description,
    this.before,
    this.after,
  });

  final String id;
  final String action;
  final String entryId;
  final DateTime happenedAt;
  final String description;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'entryId': entryId,
      'happenedAt': happenedAt.toIso8601String(),
      'description': description,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
    };
  }

  factory OvertimeAuditEvent.fromJson(Map<dynamic, dynamic> json) {
    return OvertimeAuditEvent(
      id: json['id'] as String,
      action: json['action'] as String,
      entryId: json['entryId'] as String,
      happenedAt: DateTime.parse(json['happenedAt'] as String),
      description: json['description'] as String,
      before: _optionalMap(json['before']),
      after: _optionalMap(json['after']),
    );
  }

  static Map<String, dynamic>? _optionalMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
