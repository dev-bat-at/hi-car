import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Overlay entry point - runs in separate Flutter engine instance
@pragma("vm:entry-point")
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
      home: const OverlayBubble(),
    );
  }
}

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  // Track if bubble is currently dragged into the close zone
  bool _isInCloseZone = false;
  int _lastCheckTime = 0;

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _red = Color(0xFFFF3D71);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    
    // Ensure the overlay size is strictly compact circular on start
    _safeResizeOverlay(80, 80, true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _safeResizeOverlay(int width, int height, bool enableDrag) async {
    try {
      await FlutterOverlayWindow.resizeOverlay(width, height, enableDrag);
    } catch (e) {
      debugPrint("Overlay resize failed: $e");
    }
  }

  Future<void> _toggleExpand() async {
    if (_isInCloseZone) return; // Don't toggle when in close zone
    
    if (!_expanded) {
      // 1. Expand the window boundary first so the menu content is not clipped
      await _safeResizeOverlay(80, 380, true);
      setState(() => _expanded = true);
      _animController.forward();
    } else {
      // 2. Collapse menu content
      setState(() => _expanded = false);
      await _animController.reverse();
      // 3. Shrink window boundary back to compact circle after animation completes
      await _safeResizeOverlay(80, 80, true);
    }
  }

  Future<void> _sendAction(String action) async {
    await FlutterOverlayWindow.shareData({'action': action});
    // Auto collapse after pressing an action
    if (_expanded) {
      await _toggleExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width > 0 ? screenSize.width : 1080.0;
    final screenHeight = screenSize.height > 0 ? screenSize.height : 2400.0;

    return Material(
      color: Colors.transparent,
      child: Listener(
        onPointerMove: (event) async {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Throttle getOverlayPosition check to 100ms to prevent lag/skipped frames
          if (now - _lastCheckTime > 100) {
            _lastCheckTime = now;
            try {
              final pos = await FlutterOverlayWindow.getOverlayPosition();
              // Close Zone: Bottom 12% of screen height, and horizontally near center
              final inZone = pos.y > (screenHeight - 280) &&
                  pos.x > (screenWidth / 2 - 160) &&
                  pos.x < (screenWidth / 2 + 160);

              if (inZone != _isInCloseZone) {
                setState(() {
                  _isInCloseZone = inZone;
                });
              }
            } catch (_) {}
          }
        },
        onPointerUp: (event) async {
          if (_isInCloseZone) {
            try {
              await FlutterOverlayWindow.closeOverlay();
            } catch (_) {}
          }
        },
        child: AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            final activeColor = _isInCloseZone ? _red : _cyan;

            return Container(
              width: 64.0,
              clipBehavior: Clip.antiAlias, // Critical: Prevents RenderFlex overflow errors!
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              decoration: BoxDecoration(
                color: _bg.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: activeColor.withOpacity(_isInCloseZone ? 0.95 : 0.65),
                  width: _isInCloseZone ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(_isInCloseZone ? 0.6 : 0.35),
                    blurRadius: _isInCloseZone ? 20 : 10,
                    spreadRadius: _isInCloseZone ? 2 : 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main bubble icon (acts as drag handle and toggle)
                  GestureDetector(
                    onTap: _toggleExpand,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isInCloseZone
                              ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                              : [const Color(0xFF00E5FF), const Color(0xFF0072FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isInCloseZone
                            ? Icons.delete_forever_rounded
                            : (_expanded ? Icons.close_rounded : Icons.volume_up_rounded),
                        color: Colors.black,
                        size: 24.0,
                      ),
                    ),
                  ),

                  // Expandable Menu Items
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    axisAlignment: -1,
                    child: Column(
                      children: [
                        const SizedBox(height: 8.0),
                        _OverlayActionButton(
                          icon: Icons.waving_hand_rounded,
                          color: _cyan,
                          onTap: () => _sendAction('play_greeting'),
                        ),
                        const SizedBox(height: 8.0),
                        _OverlayActionButton(
                          icon: Icons.directions_car_rounded,
                          color: const Color(0xFF00E676),
                          onTap: () => _sendAction('play_goodbye'),
                        ),
                        const SizedBox(height: 8.0),
                        _OverlayActionButton(
                          icon: Icons.stop_circle_rounded,
                          color: _red,
                          onTap: () => _sendAction('stop_audio'),
                        ),
                        const SizedBox(height: 8.0),
                        _OverlayActionButton(
                          icon: Icons.open_in_new_rounded,
                          color: Colors.white,
                          onTap: () => _sendAction('open_app'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(
            color: color.withOpacity(0.35),
            width: 1.0,
          ),
        ),
        child: Icon(icon, color: color, size: 20.0),
      ),
    );
  }
}
