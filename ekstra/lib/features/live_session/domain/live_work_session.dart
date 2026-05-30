class LiveWorkSession {
  const LiveWorkSession({
    required this.id,
    required this.startedAt,
    required this.totalBreakSeconds,
    this.breakStartedAt,
  });

  final String id;
  final DateTime startedAt;
  final int totalBreakSeconds;
  final DateTime? breakStartedAt;

  bool get isOnBreak => breakStartedAt != null;

  int elapsedSeconds(DateTime now) {
    return now.difference(startedAt).inSeconds.clamp(0, 1 << 31);
  }

  int breakSeconds(DateTime now) {
    final activeBreak = breakStartedAt == null
        ? 0
        : now.difference(breakStartedAt!).inSeconds;
    return (totalBreakSeconds + activeBreak).clamp(0, 1 << 31);
  }

  int netSeconds(DateTime now) {
    return (elapsedSeconds(now) - breakSeconds(now)).clamp(0, 1 << 31);
  }

  double netHours(DateTime now) => netSeconds(now) / 3600;

  LiveWorkSession copyWith({
    int? totalBreakSeconds,
    DateTime? breakStartedAt,
    bool clearBreakStartedAt = false,
  }) {
    return LiveWorkSession(
      id: id,
      startedAt: startedAt,
      totalBreakSeconds: totalBreakSeconds ?? this.totalBreakSeconds,
      breakStartedAt: clearBreakStartedAt
          ? null
          : breakStartedAt ?? this.breakStartedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'totalBreakSeconds': totalBreakSeconds,
      'breakStartedAt': breakStartedAt?.toIso8601String(),
    };
  }

  factory LiveWorkSession.fromJson(Map<dynamic, dynamic> json) {
    final breakStartedAt = json['breakStartedAt'];
    return LiveWorkSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      totalBreakSeconds: (json['totalBreakSeconds'] as num?)?.toInt() ?? 0,
      breakStartedAt: breakStartedAt is String
          ? DateTime.tryParse(breakStartedAt)
          : null,
    );
  }
}
