import 'package:ekstra/core/config/supabase_config.dart';
import 'package:ekstra/features/auth/domain/auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AuthSession> continueAsGuest() async => AuthSession.guest();

  @override
  Future<AuthSession> currentSession() async {
    if (!SupabaseConfig.isConfigured) return AuthSession.guest();
    final user = _client.auth.currentUser;
    if (user == null) return AuthSession.guest();
    return _sessionFromUser(user);
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Giris yapilamadi. E-posta ve sifreni kontrol et.');
    }
    return _sessionFromUser(user);
  }

  @override
  Future<AuthSession> signOut({required bool keepLocalData}) async {
    await _client.auth.signOut();
    return AuthSession.guest();
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Hesap olusturulamadi. Bilgilerini kontrol et.');
    }
    if (response.session == null) {
      throw StateError(
        'Hesap olusturuldu. E-postana gelen dogrulama baglantisini onayladiktan sonra giris yap.',
      );
    }
    return _sessionFromUser(user);
  }

  AuthSession _sessionFromUser(User user) {
    return AuthSession(
      mode: AuthMode.authenticated,
      email: user.email ?? '',
      isCloudSyncEnabled: false,
      updatedAt: DateTime.now(),
    );
  }
}
