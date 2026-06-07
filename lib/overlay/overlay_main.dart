import 'dart:isolate';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const OverlayStrip(),
    );
  }
}

class OverlayStrip extends StatefulWidget {
  const OverlayStrip({super.key});

  @override
  State<OverlayStrip> createState() => _OverlayStripState();
}

class _OverlayStripState extends State<OverlayStrip> {
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _skyBlue = Color(0xFF005CFF);
  bool _isPlaying = false;
  String? messageFromOverlay;
  BoxShape _currentShape = BoxShape.circle;

  SendPort? homePort;

  int _toPhysicalPixels(double logicalSize) {
    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    return (logicalSize * ratio).round();
  }

  @override
  void initState() {
    super.initState();
    // Listen for data from the main app if needed
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data.containsKey('isPlaying')) {
        setState(() {
          _isPlaying = data['isPlaying'];
        });
      }
    });
  }

  Future<void> _sendAction(String action) async {
    try {
      // Tìm cổng đã đăng ký ở main app
      final SendPort? sendPort =
          IsolateNameServer.lookupPortByName('overlay_action_port');

      if (sendPort != null) {
        // Bắn data đi
        sendPort.send({'action': action});
        print('Overlay: Đã gửi thành công action [$action] qua Isolate');
      } else {
        print(
            'Overlay: Không tìm thấy cổng overlay_action_port. Có thể main app chưa đăng ký.');
      }
    } catch (e) {
      print('Overlay: Lỗi khi gửi action qua Isolate: $e');
    }
  }

  Future<void> _toggleMusic() async {
    setState(() => _isPlaying = !_isPlaying);
    await _sendAction(_isPlaying ? 'play_greeting' : 'stop_audio');
  }

  Future<void> _openApp() async {
    await _sendAction('open_app');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: Stack(
        children: [
          // 1. Background layer
          Positioned.fill(
            child: GestureDetector(
              onTap: () async {
                if (_currentShape == BoxShape.rectangle) {
                  await FlutterOverlayWindow.resizeOverlay(
                    _toPhysicalPixels(50),
                    _toPhysicalPixels(100),
                    true,
                  );
                  setState(() {
                    _currentShape = BoxShape.circle;
                  });
                } else {
                  await FlutterOverlayWindow.resizeOverlay(
                    WindowSize.matchParent,
                    WindowSize.matchParent,
                    false,
                  );
                  setState(() {
                    _currentShape = BoxShape.rectangle;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _skyBlue,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // 2. Buttons layer
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildNeonButton(
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    iconColor: _isPlaying ? _neonCyan : Colors.white,
                    isGlow: _isPlaying,
                    onTap: _toggleMusic,
                  ),
                ),
                Expanded(
                  child: _buildNeonButton(
                    icon: Icons.open_in_new_rounded,
                    iconColor: Colors.white,
                    isGlow: false,
                    onTap: () {
                      print('Nhấn mở app');
                      _openApp();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton({
    required IconData icon,
    required Color iconColor,
    required bool isGlow,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0A1929),
            border: Border.all(color: Colors.white),
            boxShadow: null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
              shadows: isGlow
                  ? [
                      Shadow(color: iconColor, blurRadius: 15),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
