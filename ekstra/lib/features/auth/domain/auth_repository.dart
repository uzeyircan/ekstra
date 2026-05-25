import 'package:ekstra/features/auth/domain/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> currentSession();
  Future<AuthSession> continueAsGuest();
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<AuthSession> signOut({required bool keepLocalData});
}
