import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayDebugStore {
  OverlayDebugStore._();

  static const String _prefsKey = 'overlay_last_error';
  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(_prefsKey);
  }

  static Future<void> record(String message) async {
    final stamped = '[${DateTime.now().toIso8601String()}] $message';
    notifier.value = stamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, stamped);
  }

  static Future<void> clear() async {
    notifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

class OverlayProvider extends ChangeNotifier {
  bool _isOverlayShowing = false;
  bool _hasPermission = false;
  bool _isBubbleEnabled = true;

  bool get isOverlayShowing => _isOverlayShowing;
  bool get hasPermission => _hasPermission;
  bool get isBubbleEnabled => _isBubbleEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBubbleEnabled = prefs.getBool('is_bubble_enabled') ?? true;
    await OverlayDebugStore.load();
    await checkPermission();
    await syncOverlayState();
  }

  Future<void> checkPermission() async {
    try {
      _hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      _hasPermission = false;
    }
    notifyListeners();
  }

  Future<void> syncOverlayState() async {
    try {
      _isOverlayShowing = await FlutterOverlayWindow.isActive();
    } catch (_) {
      _isOverlayShowing = false;
    }
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    try {
      await FlutterOverlayWindow.requestPermission();
      await checkPermission();
    } catch (_) {
      _hasPermission = false;
      notifyListeners();
    }
    return _hasPermission;
  }

  Future<bool> setBubbleEnabled(bool value) async {
    if (value) {
      final granted = await requestPermission();
      if (!granted) {
        _isBubbleEnabled = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_bubble_enabled', false);
        notifyListeners();
        return false;
      }
    }

    _isBubbleEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_bubble_enabled', value);
    notifyListeners();
    
    if (value) {
      // If enabled and app is in background, it will show automatically.
    } else {
      await hideOverlay();
    }
    return true;
  }

  Future<void> showOverlay() async {
    if (!_isBubbleEnabled) return;
    await checkPermission();
    if (!_hasPermission) return;
    
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (!active) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.focusPointer,
          alignment: OverlayAlignment.centerRight,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 84,
          width: 84,
        );
      }
      await syncOverlayState();
    } catch (_) {}
  }

  Future<void> hideOverlay() async {
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active) {
        await FlutterOverlayWindow.closeOverlay();
      }
      await syncOverlayState();
    } catch (_) {}
  }
}
