class OvertimeDataHealth {
  const OvertimeDataHealth({
    required this.entryCount,
    required this.snapshotCount,
    required this.archiveCount,
    required this.auditEventCount,
    required this.hasRestorableBackup,
    this.latestEntryUpdatedAt,
    this.latestSnapshotAt,
    this.latestAuditAt,
  });

  final int entryCount;
  final int snapshotCount;
  final int archiveCount;
  final int auditEventCount;
  final bool hasRestorableBackup;
  final DateTime? latestEntryUpdatedAt;
  final DateTime? latestSnapshotAt;
  final DateTime? latestAuditAt;

  bool get isHealthy => entryCount == 0 || hasRestorableBackup;
}
