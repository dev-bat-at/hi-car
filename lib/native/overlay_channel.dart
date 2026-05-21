import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Wrapper for flutter_overlay_window communication
class OverlayChannel {
  OverlayChannel._();
  static final OverlayChannel instance = OverlayChannel._();

  /// Send message from main app to overlay
  Future<void> sendToOverlay(Map<String, dynamic> data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
    } catch (_) {}
  }

  /// Listen for messages from overlay
  Stream<dynamic>? get overlayMessages {
    try {
      return FlutterOverlayWindow.overlayListener;
    } catch (_) {
      return null;
    }
  }
}
