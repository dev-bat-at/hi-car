import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatus {
  final bool bluetooth;
  final bool bluetoothScan;
  final bool bluetoothConnect;
  final bool notification;
  final bool overlay;
  final bool batteryOptimization;

  const PermissionStatus({
    this.bluetooth = false,
    this.bluetoothScan = false,
    this.bluetoothConnect = false,
    this.notification = false,
    this.overlay = false,
    this.batteryOptimization = false,
  });

  bool get allGranted =>
      bluetoothConnect && notification;

  int get grantedCount {
    int count = 0;
    if (bluetooth) count++;
    if (bluetoothScan) count++;
    if (bluetoothConnect) count++;
    if (notification) count++;
    if (overlay) count++;
    if (batteryOptimization) count++;
    return count;
  }

  int get totalCount => 6;
}

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _status = const PermissionStatus();
  bool _isChecking = false;

  PermissionStatus get status => _status;
  bool get isChecking => _isChecking;
  bool get allGranted => _status.allGranted;

  Future<void> checkAllPermissions() async {
    _isChecking = true;
    notifyListeners();

    try {
      final btStatus = await Permission.bluetooth.status;
      final btScanStatus = await Permission.bluetoothScan.status;
      final btConnectStatus = await Permission.bluetoothConnect.status;
      final notifStatus = await Permission.notification.status;

      _status = PermissionStatus(
        bluetooth: btStatus.isGranted,
        bluetoothScan: btScanStatus.isGranted,
        bluetoothConnect: btConnectStatus.isGranted,
        notification: notifStatus.isGranted,
        overlay: false, // checked separately via flutter_overlay_window
        batteryOptimization: false, // checked separately
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

  Future<void> requestAllPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();
    await checkAllPermissions();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
