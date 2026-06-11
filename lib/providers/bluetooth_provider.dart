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
  List<BluetoothDeviceModel> _scannedDevices = [];
  bool _isScanning = false;
  final Map<String, bool> _connectingDevices = {};
  Future<bool> Function()? onTargetConnected;

  List<BluetoothDeviceModel> get pairedDevices => _pairedDevices;
  BluetoothDeviceModel? get targetDevice => _targetDevice;
  int get delaySeconds => _delaySeconds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTargetDevice => _targetDevice != null;
  List<BluetoothDeviceModel> get scannedDevices => _scannedDevices;
  bool get isScanning => _isScanning;
  Map<String, bool> get connectingDevices => _connectingDevices;

  // ===== Init =====

  Future<void> init() async {
    BluetoothChannel.instance.init();

    // Register listener for native connection status updates (Set early to avoid missing events)
    BluetoothChannel.instance
        .setConnectionChangeHandler((address, action) async {
      await loadPairedDevices();

      // If a device just connected and it matches our target, trigger autoplay if in foreground
      debugPrint(
          'BT Handler: action=$action, incoming=$address, target=${_targetDevice?.address}');
      if (action == 'connected' &&
          _targetDevice?.address.toLowerCase() == address.toLowerCase()) {
        debugPrint('BT Handler: MATCH FOUND, triggering greeting...');
        if (onTargetConnected != null) {
          await onTargetConnected!();
        }
      }
    });

    await _loadSavedTarget();
    await loadPairedDevices();

    BluetoothChannel.instance.setDiscoveryHandler((raw) async {
      final device = BluetoothDeviceModel.fromMap(raw);
      debugPrint('Found Bluetooth device: ${device.name} (${device.address})');
      // Check if already in scanned or paired list
      if (!_pairedDevices.any((d) => d.address == device.address) &&
          !_scannedDevices.any((d) => d.address == device.address)) {
        _scannedDevices.add(device);
        notifyListeners();
      }
    }, () async {
      _isScanning = false;
      await loadPairedDevices();
      notifyListeners();
    });
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

  // ===== Scan Devices =====

  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _scannedDevices.clear();
    notifyListeners();

    final started = await BluetoothChannel.instance.startDiscovery();
    if (!started) {
      _isScanning = false;
      _error = 'Không thể bắt đầu tìm kiếm';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    await BluetoothChannel.instance.stopDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  // ===== Toggle Connection =====

  Future<void> toggleDeviceConnection(BluetoothDeviceModel device) async {
    final address = device.address;
    if (_connectingDevices[address] == true) return;

    _connectingDevices[address] = true;
    notifyListeners();

    try {
      if (device.isConnected) {
        await BluetoothChannel.instance.disconnectDevice(address);
        // Optimistically update to disconnected
        _pairedDevices = _pairedDevices
            .map((d) =>
                d.address == address ? d.copyWith(isConnected: false) : d)
            .toList();
        notifyListeners();
      } else {
        // Automatically mark as target device when attempting connection
        await setTargetDevice(device);
        await BluetoothChannel.instance.connectDevice(address);
      }

      // Refresh list to sync with native reality
      await Future.delayed(const Duration(milliseconds: 2000));
      await loadPairedDevices();
    } catch (_) {
    } finally {
      _connectingDevices.remove(address);
      notifyListeners();
    }
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
    _pairedDevices =
        _pairedDevices.map((d) => d.copyWith(isSelected: false)).toList();

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
      _targetDevice =
          BluetoothDeviceModel(name: name, address: address, isSelected: true);
    }
    notifyListeners();
  }
}
