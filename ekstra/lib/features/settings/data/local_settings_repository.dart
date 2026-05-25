import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/settings/domain/settings_repository.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._hive);

  final HiveService _hive;

  @override
  Future<UserSettings> get() async {
    final value = _hive.settingsBox.get(AppConstants.settingsKey);
    if (value == null) return UserSettings.defaults();
    return UserSettings.fromJson(value as Map<dynamic, dynamic>);
  }

  @override
  Future<void> save(UserSettings settings) async {
    await _hive.settingsBox.put(AppConstants.settingsKey, settings.toJson());
    await _hive.settingsBox.flush();
  }

  @override
  Future<void> clear() async {
    await _hive.settingsBox.clear();
    await _hive.settingsBox.flush();
  }
}
