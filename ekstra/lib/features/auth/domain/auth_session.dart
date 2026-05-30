enum AuthMode {
  guest('Hesapsız kullanım'),
  authenticated('Hesaplı kullanım');

  const AuthMode(this.label);

  final String label;

  static AuthMode fromName(String value) {
    return AuthMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AuthMode.guest,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.mode,
    required this.email,
    required this.isCloudSyncEnabled,
    required this.updatedAt,
  });

  factory AuthSession.guest() {
    return AuthSession(
      mode: AuthMode.guest,
      email: '',
      isCloudSyncEnabled: false,
      updatedAt: DateTime.now(),
    );
  }

  final AuthMode mode;
  final String email;
  final bool isCloudSyncEnabled;
  final DateTime updatedAt;

  bool get isAuthenticated => mode == AuthMode.authenticated;

  AuthSession copyWith({
    AuthMode? mode,
    String? email,
    bool? isCloudSyncEnabled,
    DateTime? updatedAt,
  }) {
    return AuthSession(
      mode: mode ?? this.mode,
      email: email ?? this.email,
      isCloudSyncEnabled: isCloudSyncEnabled ?? this.isCloudSyncEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'email': email,
      'isCloudSyncEnabled': isCloudSyncEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<dynamic, dynamic> json) {
    return AuthSession(
      mode: AuthMode.fromName((json['mode'] as String?) ?? AuthMode.guest.name),
      email: (json['email'] as String?) ?? '',
      isCloudSyncEnabled: (json['isCloudSyncEnabled'] as bool?) ?? false,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
