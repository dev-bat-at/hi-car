import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Flutter → Kotlin bridge for AudioForegroundService control
class ServiceChannel {
  ServiceChannel._();
  static final ServiceChannel instance = ServiceChannel._();

  static const _channel = MethodChannel(AppConstants.serviceChannel);

  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (_) {}
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (_) {}
  }

  Future<void> playGreeting({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGreeting', {'audioPath': audioPath});
    } on PlatformException catch (_) {}
  }

  Future<void> playGoodbye({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGoodbye', {'audioPath': audioPath});
    } on PlatformException catch (_) {}
  }

  Future<void> stopAudio() async {
    try {
      await _channel.invokeMethod('stopAudio');
    } on PlatformException catch (_) {}
  }

  Future<void> openApp() async {
    try {
      await _channel.invokeMethod('openApp');
    } on PlatformException catch (_) {}
  }
}
