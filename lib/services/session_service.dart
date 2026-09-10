import 'package:hive/hive.dart';

class SessionService {
  static const String _appStateBox = 'app_state';
  static const String _setupKey = 'setupComplete';
  static const String _userIdKey = 'loggedInUserId';

  Future<Box> get _box async => await Hive.openBox(_appStateBox);

  Future<void> saveUserId(String userId) async {
    final box = await _box;
    await box.put(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final box = await _box;
    return box.get(_userIdKey) as String?;
  }

  // Whether the first admin account was already created on this device.
  Future<bool> isSetupComplete() async {
    final box = await _box;
    return box.get(_setupKey) == true;
  }

  Future<void> markSetupComplete() async {
    final box = await _box;
    await box.put(_setupKey, true);
  }

  Future<void> clear() async {
    final box = await _box;
    await box.delete(_userIdKey);
  }
}
