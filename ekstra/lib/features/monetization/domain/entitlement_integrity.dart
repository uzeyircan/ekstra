import 'package:ekstra/core/services/integrity_hash_service.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';

class EntitlementIntegrity {
  const EntitlementIntegrity._();

  static const _localSalt = 'ekstra_entitlement_v1';

  static String signatureFor(UserEntitlement entitlement) {
    return IntegrityHashService.hash(
      [
        _localSalt,
        entitlement.isPro,
        entitlement.source,
        entitlement.productId,
        entitlement.purchaseToken,
        entitlement.updatedAt.toIso8601String(),
      ].join('|'),
    );
  }

  static bool isValid(UserEntitlement entitlement) {
    if (!entitlement.isPro) return true;
    return entitlement.signature == signatureFor(entitlement);
  }
}
