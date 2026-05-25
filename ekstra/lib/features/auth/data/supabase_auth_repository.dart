import 'package:ekstra/core/config/supabase_config.dart';
import 'package:ekstra/features/auth/domain/auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_session.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository();

  Never _notConfigured() {
    throw StateError(
      SupabaseConfig.isConfigured
          ? 'Supabase auth package is not wired yet.'
          : 'Supabase URL and anon key are not configured.',
    );
  }

  @override
  Future<AuthSession> continueAsGuest() async => AuthSession.guest();

  @override
  Future<AuthSession> currentSession() async => AuthSession.guest();

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async => _notConfigured();

  @override
  Future<AuthSession> signOut({required bool keepLocalData}) async =>
      AuthSession.guest();

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async => _notConfigured();
}
