import 'package:ekstra/features/monetization/domain/user_entitlement.dart';

abstract class EntitlementRepository {
  Future<UserEntitlement> get();

  Future<void> save(UserEntitlement entitlement);
}
