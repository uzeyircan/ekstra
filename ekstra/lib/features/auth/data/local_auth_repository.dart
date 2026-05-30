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
    final normalizedEmail = _normalizeEmail(email);
    _validateCredentials(normalizedEmail, password);
    final accounts = _accounts();
    final account = accounts[normalizedEmail];
    if (account == null) {
      throw StateError('Bu e-posta ile kayitli yerel hesap bulunamadi.');
    }
    if (account['passwordVerifier'] !=
        _passwordVerifier(normalizedEmail, password)) {
      throw StateError('E-posta veya sifre hatali.');
    }
    final session = AuthSession(
      mode: AuthMode.authenticated,
      email: normalizedEmail,
      isCloudSyncEnabled: false,
      updatedAt: DateTime.now(),
    );
    await _save(session);
    return session;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateCredentials(normalizedEmail, password);
    final accounts = _accounts();
    if (accounts.containsKey(normalizedEmail)) {
      throw StateError('Bu e-posta ile zaten yerel hesap var.');
    }
    accounts[normalizedEmail] = {
      'email': normalizedEmail,
      'passwordVerifier': _passwordVerifier(normalizedEmail, password),
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _hive.authBox.put(AppConstants.localAuthAccountsKey, accounts);
    await _hive.authBox.flush();
    final session = AuthSession(
      mode: AuthMode.authenticated,
      email: normalizedEmail,
      isCloudSyncEnabled: false,
      updatedAt: DateTime.now(),
    );
    await _save(session);
    return session;
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

  Map<String, Map<String, dynamic>> _accounts() {
    final value = _hive.authBox.get(AppConstants.localAuthAccountsKey);
    if (value is! Map) return {};
    return value.map(
      (key, account) =>
          MapEntry(key.toString(), Map<String, dynamic>.from(account as Map)),
    );
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  void _validateCredentials(String email, String password) {
    if (!email.contains('@') || !email.contains('.')) {
      throw StateError('Gecerli bir e-posta gir.');
    }
    if (password.length < 6) {
      throw StateError('Sifre en az 6 karakter olmali.');
    }
  }

  String _passwordVerifier(String email, String password) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$email:$password:ekstra-local-auth'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
