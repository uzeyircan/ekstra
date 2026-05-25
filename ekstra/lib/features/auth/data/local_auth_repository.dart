import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/auth/domain/auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_session.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository(this._hive);

  final HiveService _hive;

  @override
  Future<AuthSession> currentSession() async {
    final value = _hive.authBox.get(AppConstants.authSessionKey);
    if (value == null) return AuthSession.guest();
    return AuthSession.fromJson(value as Map<dynamic, dynamic>);
  }

  @override
  Future<AuthSession> continueAsGuest() async {
    final session = AuthSession.guest();
    await _save(session);
    return session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Supabase auth is not configured yet.');
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Supabase auth is not configured yet.');
  }

  @override
  Future<AuthSession> signOut({required bool keepLocalData}) async {
    final session = AuthSession.guest();
    await _save(session);
    return session;
  }

  Future<void> _save(AuthSession session) async {
    await _hive.authBox.put(AppConstants.authSessionKey, session.toJson());
    await _hive.authBox.flush();
  }
}
