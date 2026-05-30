import 'dart:async';

import 'package:ekstra/features/monetization/domain/entitlement_service.dart';
import 'package:ekstra/features/monetization/domain/pro_product.dart';
import 'package:ekstra/features/monetization/domain/purchase_result.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService(this._entitlementService) {
    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
  }

  final EntitlementService _entitlementService;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;

  Future<ProProduct> loadProProduct() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) return ProProduct.unavailable();

    final response = await _iap.queryProductDetails({
      ProProduct.lifetimeProductId,
    });
    if (response.productDetails.isEmpty) return ProProduct.unavailable();

    _product = response.productDetails.first;
    return ProProduct(
      id: _product!.id,
      title: _product!.title,
      description: _product!.description,
      price: _product!.price,
      isAvailable: true,
    );
  }

  Future<PurchaseResult> buyPro() async {
    final product = _product;
    if (!await _iap.isAvailable()) {
      return const PurchaseResult(
        status: PurchaseResultStatus.storeUnavailable,
      );
    }
    if (product == null) {
      final loaded = await loadProProduct();
      if (!loaded.isAvailable || _product == null) {
        return const PurchaseResult(
          status: PurchaseResultStatus.productUnavailable,
          message: 'Pro ürünü mağazada bulunamadı.',
        );
      }
    }

    final details = PurchaseParam(productDetails: _product!);
    final started = await _iap.buyNonConsumable(purchaseParam: details);
    return started
        ? const PurchaseResult(status: PurchaseResultStatus.started)
        : const PurchaseResult(status: PurchaseResultStatus.failed);
  }

  Future<PurchaseResult> restorePurchases() async {
    if (!await _iap.isAvailable()) {
      return const PurchaseResult(
        status: PurchaseResultStatus.storeUnavailable,
      );
    }
    await _iap.restorePurchases();
    return const PurchaseResult(status: PurchaseResultStatus.restored);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != ProProduct.lifetimeProductId) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _entitlementService.grantPro(
          source: purchase.status.name,
          productId: purchase.productID,
          purchaseToken: purchase.verificationData.serverVerificationData,
        );
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
