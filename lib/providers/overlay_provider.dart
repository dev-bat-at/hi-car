import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await checkPermission();
    
    // Check if overlay is already active in system
    try {
      _isOverlayShowing = await FlutterOverlayWindow.isActive();
    } catch (_) {
      _isOverlayShowing = false;
    }
    notifyListeners();
  }

  Future<void> checkPermission() async {
    try {
      _hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      _hasPermission = false;
    }
    notifyListeners();
  }

  Future<void> requestPermission() async {
    try {
      await FlutterOverlayWindow.requestPermission();
      await checkPermission();
    } catch (_) {}
  }

  Future<void> setBubbleEnabled(bool value) async {
    _isBubbleEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_bubble_enabled', value);
    notifyListeners();
    
    if (value) {
      // If enabled and app is in background, it will show automatically.
    } else {
      await hideOverlay();
    }
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
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.centerRight,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 80, // Start with a circular compact boundary
          width: 80,
        );
      }
      _isOverlayShowing = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> hideOverlay() async {
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active) {
        await FlutterOverlayWindow.closeOverlay();
      }
      _isOverlayShowing = false;
      notifyListeners();
    } catch (_) {}
  }
}
