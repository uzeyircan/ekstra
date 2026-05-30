import 'package:ekstra/features/monetization/domain/entitlement_integrity.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user entitlement serializes pro state', () {
    final unsigned = UserEntitlement(
      isPro: true,
      source: 'debug_mock',
      updatedAt: DateTime(2026, 5, 30, 10),
    );
    final entitlement = unsigned.copyWith(
      signature: EntitlementIntegrity.signatureFor(unsigned),
    );

    final restored = UserEntitlement.fromJson(entitlement.toJson());

    expect(restored.isPro, isTrue);
    expect(restored.source, 'debug_mock');
    expect(restored.updatedAt, DateTime(2026, 5, 30, 10));
    expect(EntitlementIntegrity.isValid(restored), isTrue);
  });

  test('user entitlement detects tampered pro state', () {
    final free = UserEntitlement.free();
    final tampered = free.copyWith(isPro: true, source: 'purchased');

    expect(EntitlementIntegrity.isValid(tampered), isFalse);
  });
}
