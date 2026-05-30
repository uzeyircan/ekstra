class OvertimeDataHealth {
  const OvertimeDataHealth({
    required this.entryCount,
    required this.snapshotCount,
    required this.archiveCount,
    required this.auditEventCount,
    required this.hasRestorableBackup,
    required this.isIntegrityVerified,
    this.latestEntryUpdatedAt,
    this.latestSnapshotAt,
    this.latestAuditAt,
    this.latestManualBackupAt,
    this.latestIntegrityCheckAt,
  });

  final int entryCount;
  final int snapshotCount;
  final int archiveCount;
  final int auditEventCount;
  final bool hasRestorableBackup;
  final bool isIntegrityVerified;
  final DateTime? latestEntryUpdatedAt;
  final DateTime? latestSnapshotAt;
  final DateTime? latestAuditAt;
  final DateTime? latestManualBackupAt;
  final DateTime? latestIntegrityCheckAt;

  bool get isHealthy =>
      (entryCount == 0 || hasRestorableBackup) && isIntegrityVerified;
}
