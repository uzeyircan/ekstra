import 'package:ekstra/features/settings/domain/settings_repository.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository();

  Never _notImplemented() {
    throw UnimplementedError('Supabase repository is a future placeholder.');
  }

  @override
  Future<void> clear() async => _notImplemented();

  @override
  Future<UserSettings> get() async => _notImplemented();

  @override
  Future<void> save(UserSettings settings) async => _notImplemented();
}
