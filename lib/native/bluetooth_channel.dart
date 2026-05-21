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
}
