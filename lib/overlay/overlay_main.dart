import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

Future<void> _reportOverlayError(String message) async {
  debugPrint('Overlay error: $message');
  try {
    await FlutterOverlayWindow.shareData({
      'type': 'overlay_error',
      'message': message,
    });
  } catch (_) {}
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportOverlayError(details.exceptionAsString());
  };
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
  static const double _compactSize = 84.0;
  static const double _expandedWidth = 276.0;
  static const double _expandedHeight = 212.0;
  static const double _bubbleDockWidth = 84.0;
  static const double _panelTopInset = 6.0;
  static const double _edgePadding = 8.0;
  static const double _topPadding = 60.0;
  static const double _bottomPadding = 32.0;

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _red = Color(0xFFFF3D71);

  bool _expanded = false;
  bool _bubbleOnLeft = true;
  bool _isTransitioning = false;
  Offset _compactPosition = const Offset(_edgePadding, 180.0);
  Offset _windowPosition = const Offset(_edgePadding, 180.0);

  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );
    _initOverlaySize();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

  int _toOverlayUnit(double logical) => logical.round();

  Future<void> _initOverlaySize() async {
    await _syncWindowPosition(
      width: _expandedWidth,
      height: _expandedHeight,
      useFallback: true,
    );
    _setDockFromWindowPosition();
    await _applyFixedWindow();
  }

  Future<void> _syncWindowPosition({
    required double width,
    required double height,
    bool useFallback = false,
  }) async {
    try {
      final pos = await FlutterOverlayWindow.getOverlayPosition();
      Offset next = Offset(pos.x, pos.y);
      if (next == Offset.zero && useFallback) {
        next = const Offset(_edgePadding, 180.0);
      }
      _windowPosition = _clampPosition(next, width, height);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Overlay position sync failed: $e');
    }
  }

  Offset _clampPosition(Offset position, double width, double height) {
    final maxX = (_screenWidth - width - _edgePadding)
        .clamp(_edgePadding, double.infinity);
    final maxY = (_screenHeight - height - _bottomPadding)
        .clamp(_topPadding, double.infinity);
    return Offset(
      position.dx.clamp(_edgePadding, maxX),
      position.dy.clamp(_topPadding, maxY),
    );
  }

  Offset _snapCompactPosition(Offset position) {
    final snapX = position.dx + (_compactSize / 2) < _screenWidth / 2
        ? _edgePadding
        : _screenWidth - _compactSize - _edgePadding;
    return _clampPosition(
      Offset(snapX, position.dy),
      _compactSize,
      _compactSize,
    );
  }

  Future<void> _moveOverlay(Offset position) async {
    await FlutterOverlayWindow.moveOverlay(
      OverlayPosition(
        _toOverlayUnit(position.dx).toDouble(),
        _toOverlayUnit(position.dy).toDouble(),
      ),
    );
  }

  void _setDockFromWindowPosition() {
    _bubbleOnLeft =
        _windowPosition.dx + (_expandedWidth / 2) < _screenWidth / 2;
    _compactPosition = _snapCompactPosition(
      Offset(
        _bubbleOnLeft
            ? _windowPosition.dx
            : _windowPosition.dx + (_expandedWidth - _compactSize),
        _windowPosition.dy,
      ),
    );
    _windowPosition = _expandedWindowPositionFor(_compactPosition);
  }

  Offset _expandedWindowPositionFor(Offset compactPosition) {
    final expandedX = _bubbleOnLeft
        ? compactPosition.dx
        : compactPosition.dx - (_expandedWidth - _compactSize);
    return _clampPosition(
      Offset(expandedX, compactPosition.dy),
      _expandedWidth,
      _expandedHeight,
    );
  }

  Future<void> _applyFixedWindow() async {
    try {
      await _moveOverlay(_windowPosition);
      await FlutterOverlayWindow.resizeOverlay(
        _toOverlayUnit(_expandedWidth),
        _toOverlayUnit(_expandedHeight),
        false,
      );
    } catch (e) {
      debugPrint('Overlay fixed window resize failed: $e');
    }
  }

  Future<void> _expandOverlay() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (mounted) {
        setState(() => _expanded = true);
      }
      await _animController.forward(from: 0);
    } catch (e) {
      debugPrint('Overlay expand failed: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _collapseOverlay() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      await _animController.reverse();
    } catch (_) {}

    if (mounted) {
      setState(() => _expanded = false);
    }
    _isTransitioning = false;
  }

  Future<void> _toggleExpand() async {
    if (_expanded) {
      await _collapseOverlay();
    } else {
      await _expandOverlay();
    }
  }

  Future<void> _sendAction(String action) async {
    await FlutterOverlayWindow.shareData({'action': action});
    if (_expanded) {
      await _collapseOverlay();
    }
  }

  Future<void> _hideOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: _expandedWidth,
          height: _expandedHeight,
          child: Stack(
            children: [
              Positioned(
                left: _bubbleOnLeft ? 0 : _expandedWidth - _bubbleDockWidth,
                top: _panelTopInset,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleExpand,
                  child: _BubbleShell(isExpanded: _expanded),
                ),
              ),
              if (_expanded)
                Positioned(
                  left: _bubbleOnLeft ? 62.0 : 0.0,
                  top: _panelTopInset,
                  child: _buildMenuCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard() {
    return FadeTransition(
      opacity: _expandAnim,
      child: Container(
        width: 206.0,
        height: 190.0,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _bg.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: _cyan.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.16),
              blurRadius: 12.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 5.0,
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: _cyan,
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: Text(
                    'GIỌNG THƯƠNG GIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _collapseOverlay,
                  child: Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.waving_hand_rounded,
                      label: 'Phat loi chao',
                      color: _cyan,
                      onTap: () => _sendAction('play_greeting'),
                    ),
                    const SizedBox(height: 6.0),
                    _buildMenuItem(
                      icon: Icons.directions_car_rounded,
                      label: 'Phat tam biet',
                      color: const Color(0xFF00E676),
                      onTap: () => _sendAction('play_goodbye'),
                    ),
                    const SizedBox(height: 6.0),
                    _buildMenuItem(
                      icon: Icons.stop_circle_rounded,
                      label: 'Dung am thanh',
                      color: _red,
                      onTap: () => _sendAction('stop_audio'),
                    ),
                    const SizedBox(height: 6.0),
                    _buildMenuItem(
                      icon: Icons.open_in_new_rounded,
                      label: 'Mo ung dung',
                      color: Colors.white,
                      onTap: () => _sendAction('open_app'),
                    ),
                    const SizedBox(height: 6.0),
                    _buildMenuItem(
                      icon: Icons.visibility_off_rounded,
                      label: 'An bong bong',
                      color: const Color(0xFFFFB74D),
                      onTap: _hideOverlay,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26.0,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: color.withValues(alpha: 0.16),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleShell extends StatelessWidget {
  final bool isExpanded;

  const _BubbleShell({
    required this.isExpanded,
  });

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _bg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84.0,
      height: 84.0,
      child: Center(
        child: Container(
          width: 74.0,
          height: 74.0,
          decoration: BoxDecoration(
            color: _bg.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(
              color: _cyan.withValues(alpha: 0.8),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.26),
                blurRadius: 10.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60.0,
              height: 60.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                isExpanded ? Icons.close_rounded : Icons.volume_up_rounded,
                color: Colors.black,
                size: 28.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
