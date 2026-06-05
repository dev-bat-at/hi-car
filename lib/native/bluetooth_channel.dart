import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Flutter → Kotlin bridge for Bluetooth device management
class BluetoothChannel {
  BluetoothChannel._();
  static final BluetoothChannel instance = BluetoothChannel._();

  static const _channel = MethodChannel(AppConstants.bluetoothChannel);

  /// Returns list of paired Bluetooth devices from Android system
  Future<List<Map<dynamic, dynamic>>> getPairedDevices() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getPairedDevices');
      return result?.map((e) => e as Map<dynamic, dynamic>).toList() ?? [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Sets the target device address + delay in the native service
  Future<void> setTargetDevice({
    required String address,
    required int delay,
  }) async {
    try {
      await _channel.invokeMethod('setTargetDevice', {
        'address': address,
        'delay': delay,
      });
    } on PlatformException catch (_) {}
  }

  /// Clears the target device (disables auto-play)
  Future<void> clearTargetDevice() async {
    try {
      await _channel.invokeMethod('clearTargetDevice');
    } on PlatformException catch (_) {}
  }

  /// Initiates A2DP/Headset connection via reflection
  Future<bool> connectDevice(String address) async {
    try {
      final success = await _channel.invokeMethod<bool>('connectDevice', {'address': address});
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Initiates A2DP/Headset disconnection via reflection
  Future<bool> disconnectDevice(String address) async {
    try {
      final success = await _channel.invokeMethod<bool>('disconnectDevice', {'address': address});
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Updates connection mode on native side and SharedPreferences
  Future<void> setConnectionMode(String mode) async {
    try {
      await _channel.invokeMethod('setConnectionMode', {'mode': mode});
    } on PlatformException catch (_) {}
  }

  /// Sets up native-to-Flutter callback for connection changes
  void setConnectionChangeHandler(Future<dynamic> Function(String address, String action) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeviceConnectionChanged') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final address = args['address'] as String;
        final action = args['action'] as String;
        await handler(address, action);
      }
    });
  }
}
