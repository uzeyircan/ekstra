import 'package:ekstra/features/monetization/data/entitlement_repository.dart';
import 'package:ekstra/features/monetization/domain/entitlement_integrity.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';
import 'package:flutter/foundation.dart';

class EntitlementService {
  const EntitlementService(this._repository);

  final EntitlementRepository _repository;

  Future<UserEntitlement> getEntitlement() => _repository.get();

  Future<bool> isPro() async {
    final entitlement = await _repository.get();
    return entitlement.isPro;
  }

  Future<void> setMockPro(bool isPro) {
    if (!kDebugMode) {
      return _repository.save(UserEntitlement.free());
    }
    return _repository.save(_signed(isPro: isPro, source: 'debug_mock'));
  }

  Future<void> grantPro({
    required String source,
    String productId = 'ekstra_pro_lifetime',
    String purchaseToken = '',
  }) {
    return _repository.save(
      _signed(
        isPro: true,
        source: source,
        productId: productId,
        purchaseToken: purchaseToken,
      ),
    );
  }

  UserEntitlement _signed({
    required bool isPro,
    required String source,
    String productId = '',
    String purchaseToken = '',
  }) {
    if (!isPro) return UserEntitlement.free();
    final entitlement = UserEntitlement(
      isPro: true,
      source: source,
      productId: productId,
      purchaseToken: purchaseToken,
      updatedAt: DateTime.now(),
    );
    return entitlement.copyWith(
      signature: EntitlementIntegrity.signatureFor(entitlement),
    );
  }
}
