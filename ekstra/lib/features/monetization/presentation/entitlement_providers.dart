import 'package:ekstra/features/monetization/data/entitlement_repository.dart';
import 'package:ekstra/features/monetization/data/local_entitlement_repository.dart';
import 'package:ekstra/features/monetization/data/purchase_service.dart';
import 'package:ekstra/features/monetization/domain/entitlement_service.dart';
import 'package:ekstra/features/monetization/domain/feature_gate.dart';
import 'package:ekstra/features/monetization/domain/pro_product.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return LocalEntitlementRepository(ref.watch(hiveServiceProvider));
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(entitlementRepositoryProvider));
});

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref.watch(entitlementServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

final proProductProvider = FutureProvider<ProProduct>((ref) {
  return ref.watch(purchaseServiceProvider).loadProProduct();
});

final entitlementControllerProvider =
    AsyncNotifierProvider<EntitlementController, UserEntitlement>(
      EntitlementController.new,
    );

final featureGateProvider = Provider<FeatureGate>((ref) {
  final entitlement =
      ref.watch(entitlementControllerProvider).value ?? UserEntitlement.free();
  return FeatureGate(entitlement);
});

class EntitlementController extends AsyncNotifier<UserEntitlement> {
  EntitlementService get _service => ref.read(entitlementServiceProvider);

  @override
  Future<UserEntitlement> build() => _service.getEntitlement();

  Future<void> setMockPro(bool isPro) async {
    await _service.setMockPro(isPro);
    state = AsyncData(await _service.getEntitlement());
  }

  Future<void> refresh() async {
    state = AsyncData(await _service.getEntitlement());
  }

  Future<void> grantProFromPurchase(String source) async {
    await _service.grantPro(source: source);
    state = AsyncData(await _service.getEntitlement());
  }
}
