import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/logger.dart';

/// Flutter → Kotlin bridge for AudioForegroundService control
class ServiceChannel {
  ServiceChannel._();
  static final ServiceChannel instance = ServiceChannel._();

  static const _channel = MethodChannel(AppConstants.serviceChannel);
  VoidCallback? onPlaybackComplete;
  void Function(String type)? onPlaybackStarted;

  void init() {
    _channel.setMethodCallHandler((call) async {
      debugPrint('ServiceChannel: Received method call: ${call.method}');
      if (call.method == 'onPlaybackComplete') {
        onPlaybackComplete?.call();
      } else if (call.method == 'onPlaybackStarted') {
        onPlaybackStarted?.call(call.arguments?.toString() ?? 'greeting');
      } else if (call.method == 'onNativeError') {
        final message =
            call.arguments?.toString() ?? 'Lỗi không xác định từ Native';
        AppLogger.instance.log(
          'LỖI NATIVE: $message',
          type: 'native_error',
        );
      }
    });
  }

  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: startService error: $e');
      AppLogger.instance.log(
        'Native startService lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code, 'details': e.details?.toString()},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: startService missing plugin: $e');
      AppLogger.instance.log(
        'Plugin Service chưa đăng ký (startService): $e',
        type: 'native_error',
      );
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: stopService error: $e');
      AppLogger.instance.log(
        'Native stopService lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: stopService missing plugin: $e');
    }
  }

  Future<void> playGreeting({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGreeting', {'audioPath': audioPath});
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: playGreeting error: $e');
      AppLogger.instance.log(
        'Native playGreeting lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code, 'audioPath': audioPath},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: playGreeting missing plugin: $e');
      AppLogger.instance.log(
        'Plugin Service chưa đăng ký (playGreeting): $e',
        type: 'native_error',
      );
    }
  }

  Future<void> playGoodbye({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGoodbye', {'audioPath': audioPath});
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: playGoodbye error: $e');
      AppLogger.instance.log(
        'Native playGoodbye lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code, 'audioPath': audioPath},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: playGoodbye missing plugin: $e');
      AppLogger.instance.log(
        'Plugin Service chưa đăng ký (playGoodbye): $e',
        type: 'native_error',
      );
    }
  }

  Future<void> stopAudio() async {
    try {
      await _channel.invokeMethod('stopAudio');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: stopAudio error: $e');
      AppLogger.instance.log(
        'Native stopAudio lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: stopAudio missing plugin: $e');
    }
  }

  Future<void> showAutostartSettings() async {
    try {
      await _channel.invokeMethod('showAutostartSettings');
    } catch (e) {
      debugPrint('ServiceChannel: showAutostartSettings error: $e');
    }
  }

  Future<void> minimizeApp() async {
    try {
      await _channel.invokeMethod('minimizeApp');
    } catch (e) {
      debugPrint('ServiceChannel: minimizeApp error: $e');
    }
  }

  Future<void> openApp() async {
    try {
      await _channel.invokeMethod('openApp');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: openApp error: $e');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: openApp missing plugin: $e');
    }
  }

  Future<void> clearGreetingConfig() async {
    try {
      await _channel.invokeMethod('clearGreetingConfig');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: clearGreetingConfig error: $e');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: clearGreetingConfig missing plugin: $e');
    }
  }

  Future<void> clearGoodbyeConfig() async {
    try {
      await _channel.invokeMethod('clearGoodbyeConfig');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: clearGoodbyeConfig error: $e');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: clearGoodbyeConfig missing plugin: $e');
    }
  }

  Future<void> syncPrefs() async {
    try {
      await _channel.invokeMethod('syncPrefs');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: syncPrefs error: $e');
      AppLogger.instance.log(
        'Native syncPrefs lỗi: ${e.message}',
        type: 'native_error',
        details: {'code': e.code, 'details': e.details?.toString()},
      );
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: syncPrefs missing plugin: $e');
      AppLogger.instance.log(
        'Plugin Service chưa đăng ký (syncPrefs): $e',
        type: 'native_error',
      );
    } catch (e) {
      debugPrint('ServiceChannel: syncPrefs unknown error: $e');
      AppLogger.instance.log(
        'syncPrefs lỗi không xác định: $e',
        type: 'native_error',
      );
    }
  }
}
