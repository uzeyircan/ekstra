class CloudSyncResult {
  const CloudSyncResult({
    required this.message,
    required this.entryCount,
    required this.changedCount,
  });

  final String message;
  final int entryCount;
  final int changedCount;
}
