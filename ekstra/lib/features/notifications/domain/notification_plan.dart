enum EkstraNotificationType {
  shiftReminder,
  overtimeReminder,
  salaryDay,
  monthlySummary,
}

class NotificationPlan {
  const NotificationPlan({
    required this.id,
    required this.type,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int id;
  final EkstraNotificationType type;
  final DateTime scheduledAt;
  final String title;
  final String body;
}
