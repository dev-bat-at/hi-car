import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsProvider extends ChangeNotifier {
  bool _autoPlayEnabled = true;
  int _delaySeconds = AppConstants.defaultDelaySeconds;
  bool _bluetoothAutoPlay = true;
  bool _androidAutoEnabled = true;
  bool _showNotification = true;

  bool get autoPlayEnabled => _autoPlayEnabled;
  int get delaySeconds => _delaySeconds;
  bool get bluetoothAutoPlay => _bluetoothAutoPlay;
  bool get androidAutoEnabled => _androidAutoEnabled;
  bool get showNotification => _showNotification;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoPlayEnabled = prefs.getBool(AppConstants.keyAutoPlayEnabled) ?? true;
    _delaySeconds = prefs.getInt(AppConstants.keyDelaySeconds) ??
        AppConstants.defaultDelaySeconds;
    _bluetoothAutoPlay = prefs.getBool('bluetooth_auto_play') ?? true;
    _androidAutoEnabled = prefs.getBool('android_auto_enabled') ?? true;
    _showNotification = prefs.getBool('show_notification') ?? true;
    notifyListeners();
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlayEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoPlayEnabled, value);
    notifyListeners();
  }

  Future<void> setDelay(int seconds) async {
    _delaySeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDelaySeconds, seconds);
    notifyListeners();
  }

  Future<void> setBluetoothAutoPlay(bool value) async {
    _bluetoothAutoPlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bluetooth_auto_play', value);
    notifyListeners();
  }

  Future<void> setAndroidAutoEnabled(bool value) async {
    _androidAutoEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('android_auto_enabled', value);
    notifyListeners();
  }

  Future<void> setShowNotification(bool value) async {
    _showNotification = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_notification', value);
    notifyListeners();
  }
}
