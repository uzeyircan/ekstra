import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/monetization/data/entitlement_repository.dart';
import 'package:ekstra/features/monetization/domain/entitlement_integrity.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';

class LocalEntitlementRepository implements EntitlementRepository {
  const LocalEntitlementRepository(this._hive);

  final HiveService _hive;

  @override
  Future<UserEntitlement> get() async {
    final value = _hive.entitlementsBox.get(AppConstants.userEntitlementKey);
    if (value == null) return UserEntitlement.free();
    final entitlement = UserEntitlement.fromJson(
      value as Map<dynamic, dynamic>,
    );
    if (EntitlementIntegrity.isValid(entitlement)) return entitlement;

    await save(UserEntitlement.free());
    return UserEntitlement.free();
  }

  @override
  Future<void> save(UserEntitlement entitlement) async {
    await _hive.entitlementsBox.put(
      AppConstants.userEntitlementKey,
      entitlement.toJson(),
    );
    await _hive.entitlementsBox.flush();
  }
}
