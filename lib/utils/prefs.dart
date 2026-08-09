import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final Prefs _instance = Prefs._internal();
  factory Prefs() => _instance;
  Prefs._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    await init();
    return _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    await init();
    return _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> remove(String key) async {
    await init();
    return _prefs!.remove(key);
  }

  static const String keyPrivacyAccepted = 'privacy_accepted';
  static const String keyRealnameDone = 'realname_done';
  static const String keyRealnameName = 'realname_name';
  static const String keyRealnameIdCard = 'realname_idcard';
  static const String keyVerifyDone = 'verify_done';
  static const String keyGuideDone = 'guide_done';
  static const String keyComplianceDone = 'compliance_done';
  static const String keyDeviceId = 'device_id';
  static const String keyAndroidId = 'android_id';
  static const String keyAppStartTime = 'app_start_time';
  static const String keyAddictionWarned = 'addiction_warned';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFavorites = 'favorites_equipment';
  static const String keyCollected = 'collected_equipment_ids';
  static const String keyHistory = 'browse_history';
}
