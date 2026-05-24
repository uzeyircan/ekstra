enum OvertimeType {
  normal('Normal', 1),
  weekend('Hafta sonu', 1.5),
  holiday('Resmi tatil', 2);

  const OvertimeType(this.label, this.suggestedMultiplier);

  final String label;
  final double suggestedMultiplier;

  static OvertimeType fromName(String value) {
    return OvertimeType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => OvertimeType.normal,
    );
  }
}
