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

  // Actual position tracking
  double _currentX = 0;
  double _currentY = 0;
  bool _isInitialized = false;

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

  double get _deviceRatio {
    final views = ui.PlatformDispatcher.instance.views;
    return views.isNotEmpty ? views.first.devicePixelRatio : 3.0;
  }

  double get _screenWidth {
    final views = ui.PlatformDispatcher.instance.views;
    return views.isNotEmpty
        ? (views.first.physicalSize.width / _deviceRatio)
        : 390.0;
  }

  double get _screenHeight {
    final views = ui.PlatformDispatcher.instance.views;
    return views.isNotEmpty
        ? (views.first.physicalSize.height / _deviceRatio)
        : 844.0;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _screenWidth;
    final sh = _screenHeight;

    if (!_isInitialized) {
      _currentX = sw - 60;
      _currentY = (sh - 130) / 2;
      _isInitialized = true;
    }

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              _currentX += details.delta.dx;
              _currentY += details.delta.dy;

              // Clamp coordinates to logical screen bounds
              _currentX = _currentX.clamp(0.0, sw - w);
              _currentY = _currentY.clamp(0.0, sh - 130.0);

              final ratio = _deviceRatio;
              // Ensure we send rounded physical pixels as explicitly cast doubles
              final double px = (_currentX * ratio).roundToDouble();
              final double py = (_currentY * ratio).roundToDouble();

              FlutterOverlayWindow.moveOverlay(OverlayPosition(px, py));
            },
            onPanEnd: (details) {
              double halfScreenWidth = sw / 2;

              if (_currentX + (w / 2) < halfScreenWidth) {
                _currentX = 0;
              } else {
                _currentX = sw - w;
              }

              final ratio = _deviceRatio;
              final double px = (_currentX * ratio).roundToDouble();
              final double py = (_currentY * ratio).roundToDouble();

              FlutterOverlayWindow.moveOverlay(OverlayPosition(px, py));
            },
            child: Container(
              width: 60,
              height: 130,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepRed.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(w / 2),
              ),
              child: Column(
                children: [
                  // Music Button
                  Expanded(
                    child: _buildNeonButton(
                      icon: _isPlaying
                          ? Icons.music_off_rounded
                          : Icons.music_note_rounded,
                      iconColor: _isPlaying ? Colors.white : _neonCyan,
                      isGlow: _isPlaying,
                      onTap: _toggleMusic,
                    ),
                  ),
                  // App Button
                  Expanded(
                    child: _buildNeonButton(
                      icon: Icons.open_in_new_rounded,
                      iconColor: Colors.white,
                      isGlow: false,
                      onTap: _openApp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      child: Container(
        margin: const EdgeInsets.all(8),
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
    );
  }
}
