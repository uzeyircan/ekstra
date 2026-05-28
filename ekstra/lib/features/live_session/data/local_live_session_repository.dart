import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/live_session/domain/live_work_session.dart';

class LocalLiveSessionRepository {
  const LocalLiveSessionRepository(this._hive);

  final HiveService _hive;

  Future<LiveWorkSession?> getActive() async {
    final value = _hive.liveSessionBox.get(AppConstants.activeLiveSessionKey);
    if (value is! Map) return null;
    return LiveWorkSession.fromJson(value);
  }

  Future<void> save(LiveWorkSession session) async {
    await _hive.liveSessionBox.put(
      AppConstants.activeLiveSessionKey,
      session.toJson(),
    );
    await _hive.liveSessionBox.flush();
  }

  Future<void> clear() async {
    await _hive.liveSessionBox.delete(AppConstants.activeLiveSessionKey);
    await _hive.liveSessionBox.flush();
  }
}
