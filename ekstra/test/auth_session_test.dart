import 'package:ekstra/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest session serializes as local-only mode', () {
    final session = AuthSession.guest();
    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.mode, AuthMode.guest);
    expect(restored.isAuthenticated, isFalse);
    expect(restored.isCloudSyncEnabled, isFalse);
  });

  test('authenticated session serializes without enabling cloud sync', () {
    final session = AuthSession(
      mode: AuthMode.authenticated,
      email: 'user@example.com',
      isCloudSyncEnabled: false,
      updatedAt: DateTime(2026),
    );
    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.mode, AuthMode.authenticated);
    expect(restored.email, 'user@example.com');
    expect(restored.isAuthenticated, isTrue);
    expect(restored.isCloudSyncEnabled, isFalse);
  });
}
