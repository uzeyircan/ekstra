import 'package:ekstra/core/config/supabase_config.dart';
import 'package:ekstra/features/auth/data/local_auth_repository.dart';
import 'package:ekstra/features/auth/data/supabase_auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_session.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAuthRepository();
  }
  return LocalAuthRepository(ref.watch(hiveServiceProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession> build() => _repository.currentSession();

  Future<void> continueAsGuest() async {
    state = AsyncData(await _repository.continueAsGuest());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signUpWithEmail(email: email, password: password),
    );
  }

  Future<void> signOut({bool keepLocalData = true}) async {
    state = AsyncData(await _repository.signOut(keepLocalData: keepLocalData));
  }
}
