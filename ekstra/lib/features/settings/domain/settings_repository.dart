import 'package:ekstra/features/settings/domain/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> get();
  Future<void> save(UserSettings settings);
  Future<void> clear();
}
