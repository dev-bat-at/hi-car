import 'dart:isolate';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isGreetingPlaying = false;
  bool _isGoodbyePlaying = false;
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
      if (data is Map) {
        setState(() {
          if (data.containsKey('isPlaying')) {
            _isGreetingPlaying = data['isPlaying'];
          }
          // We can expand this logic if main app sends more specific states
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

  Future<void> _toggleGreeting() async {
    setState(() {
      _isGreetingPlaying = !_isGreetingPlaying;
      if (_isGreetingPlaying) _isGoodbyePlaying = false;
    });
    await _sendAction(_isGreetingPlaying ? 'play_greeting' : 'stop_audio');
  }

  Future<void> _toggleGoodbye() async {
    setState(() {
      _isGoodbyePlaying = !_isGoodbyePlaying;
      if (_isGoodbyePlaying) _isGreetingPlaying = false;
    });
    await _sendAction(_isGoodbyePlaying ? 'play_goodbye' : 'stop_audio');
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
                    _toPhysicalPixels(150), // Increased height for 3 buttons
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
                    icon: _isGreetingPlaying
                        ? Icons.stop_rounded
                        : Icons.waving_hand_rounded,
                    iconColor: _isGreetingPlaying ? _neonCyan : Colors.white,
                    isGlow: _isGreetingPlaying,
                    onTap: _toggleGreeting,
                  ),
                ),
                Expanded(
                  child: _buildNeonButton(
                    icon: _isGoodbyePlaying
                        ? Icons.stop_rounded
                        : Icons.directions_car_rounded,
                    iconColor: _isGoodbyePlaying ? _neonCyan : Colors.white,
                    isGlow: _isGoodbyePlaying,
                    onTap: _toggleGoodbye,
                  ),
                ),
                Expanded(
                  child: _buildNeonButton(
                    icon: Icons.launch_rounded,
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
    return _OverlayScaleButton(
      onTap: onTap,
      child: Center(
        child: ClipOval(
          child: Material(
            color: const Color(0xFF0A1929),
            child: InkWell(
              onTap: onTap,
              splashColor: iconColor.withOpacity(0.3),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                  boxShadow: isGlow
                      ? [
                          BoxShadow(
                            color: iconColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                    shadows: isGlow
                        ? [
                            Shadow(color: iconColor, blurRadius: 15),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _OverlayScaleButton({required this.child, required this.onTap});

  @override
  State<_OverlayScaleButton> createState() => _OverlayScaleButtonState();
}

class _OverlayScaleButtonState extends State<_OverlayScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
