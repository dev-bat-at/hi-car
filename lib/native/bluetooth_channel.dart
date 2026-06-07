import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Flutter → Kotlin bridge for Bluetooth device management
class BluetoothChannel {
  BluetoothChannel._();
  static final BluetoothChannel instance = BluetoothChannel._();

  static const _channel = MethodChannel(AppConstants.bluetoothChannel);

  Future<dynamic> Function(String address, String action)? _connectionHandler;
  Future<dynamic> Function(Map<dynamic, dynamic> device)? _discoveryHandler;
  VoidCallback? _onDiscoveryFinished;

  void init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceConnectionChanged':
          final args = call.arguments as Map<dynamic, dynamic>;
          await _connectionHandler?.call(
              args['address'] as String, args['action'] as String);
          break;
        case 'onDeviceFound':
          await _discoveryHandler
              ?.call(call.arguments as Map<dynamic, dynamic>);
          break;
        case 'onDiscoveryFinished':
          _onDiscoveryFinished?.call();
          break;
      }
    });
  }

  /// Returns list of paired Bluetooth devices from Android system
  Future<List<Map<dynamic, dynamic>>> getPairedDevices() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getPairedDevices');
      return result?.map((e) => e as Map<dynamic, dynamic>).toList() ?? [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Starts scanning for nearby Bluetooth devices
  Future<bool> startDiscovery() async {
    try {
      final success = await _channel.invokeMethod<bool>('startDiscovery');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Stops scanning for nearby Bluetooth devices
  Future<bool> stopDiscovery() async {
    try {
      final success = await _channel.invokeMethod<bool>('stopDiscovery');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
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
      final success = await _channel
          .invokeMethod<bool>('connectDevice', {'address': address});
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Initiates A2DP/Headset disconnection via reflection
  Future<bool> disconnectDevice(String address) async {
    try {
      final success = await _channel
          .invokeMethod<bool>('disconnectDevice', {'address': address});
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

  void setConnectionChangeHandler(
      Future<dynamic> Function(String address, String action) handler) {
    _connectionHandler = handler;
  }

  void setDiscoveryHandler(
      Future<dynamic> Function(Map<dynamic, dynamic> device) onDeviceFound,
      VoidCallback onFinished) {
    _discoveryHandler = onDeviceFound;
    _onDiscoveryFinished = onFinished;
  }
}
