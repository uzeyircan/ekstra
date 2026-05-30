class UserEntitlement {
  const UserEntitlement({
    required this.isPro,
    required this.source,
    required this.updatedAt,
    this.productId = '',
    this.purchaseToken = '',
    this.signature = '',
  });

  factory UserEntitlement.free() {
    return UserEntitlement(
      isPro: false,
      source: 'free',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final bool isPro;
  final String source;
  final DateTime updatedAt;
  final String productId;
  final String purchaseToken;
  final String signature;

  UserEntitlement copyWith({
    bool? isPro,
    String? source,
    DateTime? updatedAt,
    String? productId,
    String? purchaseToken,
    String? signature,
  }) {
    return UserEntitlement(
      isPro: isPro ?? this.isPro,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      productId: productId ?? this.productId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPro': isPro,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
      'productId': productId,
      'purchaseToken': purchaseToken,
      'signature': signature,
    };
  }

  factory UserEntitlement.fromJson(Map<dynamic, dynamic> json) {
    return UserEntitlement(
      isPro: (json['isPro'] as bool?) ?? false,
      source: (json['source'] as String?) ?? 'free',
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      productId: (json['productId'] as String?) ?? '',
      purchaseToken: (json['purchaseToken'] as String?) ?? '',
      signature: (json['signature'] as String?) ?? '',
    );
  }
}
