enum PurchaseResultStatus {
  started,
  restored,
  storeUnavailable,
  productUnavailable,
  failed,
}

class PurchaseResult {
  const PurchaseResult({required this.status, this.message = ''});

  final PurchaseResultStatus status;
  final String message;
}
