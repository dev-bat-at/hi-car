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
      AppLogger.instance
          .log('Lỗi Native startService: ${e.message}', type: 'native_error');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: startService missing plugin: $e');
      AppLogger.instance
          .log('Lỗi Native: Chưa cài đặt plugin Service', type: 'native_error');
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: stopService error: $e');
      AppLogger.instance
          .log('Lỗi Native stopService: ${e.message}', type: 'native_error');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: stopService missing plugin: $e');
    }
  }

  Future<void> playGreeting({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGreeting', {'audioPath': audioPath});
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: playGreeting error: $e');
      AppLogger.instance
          .log('Lỗi Native playGreeting: ${e.message}', type: 'native_error');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: playGreeting missing plugin: $e');
    }
  }

  Future<void> playGoodbye({required String audioPath}) async {
    try {
      await _channel.invokeMethod('playGoodbye', {'audioPath': audioPath});
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: playGoodbye error: $e');
      AppLogger.instance
          .log('Lỗi Native playGoodbye: ${e.message}', type: 'native_error');
    } on MissingPluginException catch (e) {
      debugPrint('ServiceChannel: playGoodbye missing plugin: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _channel.invokeMethod('stopAudio');
    } on PlatformException catch (e) {
      debugPrint('ServiceChannel: stopAudio error: $e');
      AppLogger.instance
          .log('Lỗi Native stopAudio: ${e.message}', type: 'native_error');
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

  Future<void> syncPrefs() async {
    try {
      await _channel.invokeMethod('syncPrefs');
    } catch (e) {
      debugPrint('ServiceChannel: syncPrefs error: $e');
      AppLogger.instance.log('Lỗi Native syncPrefs: $e', type: 'native_error');
    }
  }
}
