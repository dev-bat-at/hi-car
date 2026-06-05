import 'dart:isolate';
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
  static const Color _deepRed = Color(0xFFE91E63);
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

  Future<void> _toggleMusic() async {
    setState(() => _isPlaying = !_isPlaying);
    await FlutterOverlayWindow.shareData(
        {'action': _isPlaying ? 'play_greeting' : 'stop_audio'});
  }

  Future<void> _openApp() async {
    await FlutterOverlayWindow.shareData({'action': 'open_app'});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: Stack(
        children: [
          // Background/Expansion gesture layer
          GestureDetector(
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepRed.withOpacity(0.85),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _neonCyan.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Buttons layer
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nút điều khiển nhạc
                Expanded(
                  child: _buildNeonButton(
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    iconColor: _isPlaying ? _neonCyan : Colors.white,
                    isGlow: _isPlaying,
                    onTap: _toggleMusic,
                  ),
                ),
                // Nút mở ứng dụng
                Expanded(
                  child: _buildNeonButton(
                    icon: Icons.open_in_new_rounded,
                    iconColor: Colors.white,
                    isGlow: false,
                    onTap: () {
                      _openApp();
                      print('Nhấn mở app');
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
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
