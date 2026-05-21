import 'package:flutter/foundation.dart';
import '../data/models/bluetooth_device_model.dart';
import '../native/bluetooth_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class BluetoothProvider extends ChangeNotifier {
  List<BluetoothDeviceModel> _pairedDevices = [];
  BluetoothDeviceModel? _targetDevice;
  int _delaySeconds = AppConstants.defaultDelaySeconds;
  bool _isLoading = false;
  String? _error;

  List<BluetoothDeviceModel> get pairedDevices => _pairedDevices;
  BluetoothDeviceModel? get targetDevice => _targetDevice;
  int get delaySeconds => _delaySeconds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTargetDevice => _targetDevice != null;

  // ===== Init =====

  Future<void> init() async {
    await _loadSavedTarget();
  }

  // ===== Load Paired Devices =====

  Future<void> loadPairedDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawDevices = await BluetoothChannel.instance.getPairedDevices();
      _pairedDevices = rawDevices.map((raw) {
        final device = BluetoothDeviceModel.fromMap(raw);
        return device.copyWith(
          isSelected: device.address == (_targetDevice?.address ?? ''),
        );
      }).toList();
    } catch (e) {
      _error = 'Không thể lấy danh sách thiết bị Bluetooth';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Set Target Device =====

  Future<void> setTargetDevice(BluetoothDeviceModel device) async {
    _targetDevice = device;

    // Update selected state in list
    _pairedDevices = _pairedDevices.map((d) {
      return d.copyWith(isSelected: d.address == device.address);
    }).toList();

    // Save to prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTargetDeviceAddress, device.address);
    await prefs.setString(AppConstants.keyTargetDeviceName, device.name);

    // Send to native
    await BluetoothChannel.instance.setTargetDevice(
      address: device.address,
      delay: _delaySeconds,
    );

    notifyListeners();
  }

  Future<void> clearTargetDevice() async {
    _targetDevice = null;
    _pairedDevices = _pairedDevices.map((d) => d.copyWith(isSelected: false)).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyTargetDeviceAddress);
    await prefs.remove(AppConstants.keyTargetDeviceName);

    await BluetoothChannel.instance.clearTargetDevice();
    notifyListeners();
  }

  // ===== Set Delay =====

  Future<void> setDelaySeconds(int seconds) async {
    _delaySeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDelaySeconds, seconds);

    // Resend to native if target is already set
    if (_targetDevice != null) {
      await BluetoothChannel.instance.setTargetDevice(
        address: _targetDevice!.address,
        delay: seconds,
      );
    }
    notifyListeners();
  }

  // ===== Private =====

  Future<void> _loadSavedTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(AppConstants.keyTargetDeviceAddress) ?? '';
    final name = prefs.getString(AppConstants.keyTargetDeviceName) ?? '';
    _delaySeconds = prefs.getInt(AppConstants.keyDelaySeconds) ??
        AppConstants.defaultDelaySeconds;

    if (address.isNotEmpty) {
      _targetDevice = BluetoothDeviceModel(name: name, address: address, isSelected: true);
    }
    notifyListeners();
  }
}
