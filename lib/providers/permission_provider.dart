import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionStatus {
  final bool bluetooth;
  final bool bluetoothScan;
  final bool bluetoothConnect;
  final bool notification;
  final bool overlay;
  final bool batteryOptimization;
  final bool bootComplete;
  final bool backgroundPersistence;

  const PermissionStatus({
    this.bluetooth = false,
    this.bluetoothScan = false,
    this.bluetoothConnect = false,
    this.notification = false,
    this.overlay = false,
    this.batteryOptimization = false,
    this.bootComplete = false,
    this.backgroundPersistence = false,
  });

  bool isGrantedForMode(String mode) {
    if (mode == 'phone_bluetooth') {
      return bluetoothConnect && notification;
    } else if (mode == 'phone_android_auto') {
      return notification;
    } else if (mode == 'android_screen_box') {
      return notification && batteryOptimization;
    }
    return false;
  }

  int getGrantedCountForMode(String mode) {
    int count = 0;
    if (mode == 'phone_bluetooth') {
      if (bluetoothConnect) count++;
      if (notification) count++;
    } else if (mode == 'phone_android_auto') {
      if (notification) count++;
    } else if (mode == 'android_screen_box') {
      if (notification) count++;
      if (batteryOptimization) count++;
    }
    return count;
  }

  int getTotalCountForMode(String mode) {
    if (mode == 'phone_bluetooth') return 2;
    if (mode == 'phone_android_auto') return 1;
    if (mode == 'android_screen_box') return 2;
    return 0;
  }
}

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _status = const PermissionStatus();
  bool _isChecking = false;
  bool _isXiaomi = false;

  PermissionStatus get status => _status;
  bool get isChecking => _isChecking;
  bool get isXiaomi => _isXiaomi;

  Future<void> checkAllPermissions() async {
    _isChecking = true;
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _isXiaomi = androidInfo.manufacturer.toLowerCase().contains('xiaomi') ||
            androidInfo.manufacturer.toLowerCase().contains('poco') ||
            androidInfo.manufacturer.toLowerCase().contains('redmi');
      }
      // Small delay to ensure system settings are synchronized
      await Future.delayed(const Duration(milliseconds: 300));

      final btStatus = await Permission.bluetooth.status;
      final btScanStatus = await Permission.bluetoothScan.status;
      final btConnectStatus = await Permission.bluetoothConnect.status;
      final notifStatus = await Permission.notification.status;
      final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      final batteryGranted = batteryStatus.isGranted;

      _status = PermissionStatus(
        bluetooth: btStatus.isGranted,
        bluetoothScan: btScanStatus.isGranted,
        bluetoothConnect: btConnectStatus.isGranted,
        notification: notifStatus.isGranted,
        overlay: overlayGranted,
        batteryOptimization: batteryGranted,
        bootComplete:
            true, // System permission usually, we just track if we should show it
        backgroundPersistence: true,
      );
    } catch (_) {}

    _isChecking = false;
    notifyListeners();
  }

  Future<bool> requestBluetoothPermissions() async {
    final result = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final allGranted = result.values.every((s) => s.isGranted);
    await checkAllPermissions();
    return allGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final result = await Permission.notification.request();
    await checkAllPermissions();
    return result.isGranted;
  }

  Future<bool> requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
    await checkAllPermissions();
    return _status.overlay;
  }

  Future<bool> requestBatteryOptimizationPermission() async {
    final result = await Permission.ignoreBatteryOptimizations.request();
    await checkAllPermissions();
    return result.isGranted;
  }

  Future<bool> requestBackgroundExecutionPermissions() async {
    // 1. Notification
    await requestNotificationPermission();
    // 2. Battery
    await requestBatteryOptimizationPermission();

    await checkAllPermissions();
    return _status.notification && _status.batteryOptimization;
  }

  Future<void> requestAllPermissionsForMode(String mode) async {
    if (mode == 'phone_bluetooth') {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.notification,
      ].request();
      if (!_status.overlay) {
        await FlutterOverlayWindow.requestPermission();
      }
    } else if (mode == 'phone_android_auto') {
      await Permission.notification.request();
      if (!_status.overlay) {
        await FlutterOverlayWindow.requestPermission();
      }
    } else if (mode == 'android_screen_box') {
      await Permission.notification.request();
      await Permission.ignoreBatteryOptimizations.request();
      if (!_status.overlay) {
        await FlutterOverlayWindow.requestPermission();
      }
    }
    await checkAllPermissions();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
