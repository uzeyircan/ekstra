import 'package:ekstra/core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  late final Box<dynamic> entriesBox;
  late final Box<dynamic> settingsBox;
  late final Box<dynamic> shiftsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    entriesBox = await Hive.openBox<dynamic>(AppConstants.entriesBox);
    settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
    shiftsBox = await Hive.openBox<dynamic>(AppConstants.shiftsBox);
  }

  Future<void> clearAll() async {
    await Future.wait([
      entriesBox.clear(),
      settingsBox.clear(),
      shiftsBox.clear(),
    ]);
  }
}
