import 'package:ekstra/core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  late final Box<dynamic> entriesBox;
  late final Box<dynamic> entrySnapshotsBox;
  late final Box<dynamic> entryArchiveBox;
  late final Box<dynamic> integrityBox;
  late final Box<dynamic> settingsBox;
  late final Box<dynamic> shiftsBox;
  late final Box<dynamic> authBox;

  Future<void> init() async {
    await Hive.initFlutter();
    entriesBox = await Hive.openBox<dynamic>(AppConstants.entriesBox);
    entrySnapshotsBox = await Hive.openBox<dynamic>(
      AppConstants.entrySnapshotsBox,
    );
    entryArchiveBox = await Hive.openBox<dynamic>(AppConstants.entryArchiveBox);
    integrityBox = await Hive.openBox<dynamic>(AppConstants.integrityBox);
    settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
    shiftsBox = await Hive.openBox<dynamic>(AppConstants.shiftsBox);
    authBox = await Hive.openBox<dynamic>(AppConstants.authBox);
  }

  Future<void> clearAll() async {
    await Future.wait([
      entriesBox.clear(),
      entrySnapshotsBox.clear(),
      entryArchiveBox.clear(),
      integrityBox.clear(),
      settingsBox.clear(),
      shiftsBox.clear(),
      authBox.clear(),
    ]);
  }
}
