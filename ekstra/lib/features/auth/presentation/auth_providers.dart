import 'package:ekstra/features/auth/data/local_auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_repository.dart';
import 'package:ekstra/features/auth/domain/auth_session.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
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

  Future<void> signOut({bool keepLocalData = true}) async {
    state = AsyncData(await _repository.signOut(keepLocalData: keepLocalData));
  }
}
