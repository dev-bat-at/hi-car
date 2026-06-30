import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// Lưu ý: entry point `overlayMain` được định nghĩa trong lib/main.dart (library gốc) để
// release build (AOT) resolve được. Ở đây chỉ giữ widget OverlayApp/OverlayStrip.

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
  static const Color _neonCyan = Color(0xFF00FBFF);
  static const Color _neonBlue = Color(0xFF007BFF);

  // Kênh gọi THẲNG xuống native (đăng ký trên chính engine của nút nổi).
  // Không phụ thuộc isolate chính → bấm nút luôn phát được dù app ở nền lâu.
  static const MethodChannel _bridge =
      MethodChannel('com.hicar.ora.limited/overlay_bridge');

  bool _isGreetingPlaying = false;
  bool _isGoodbyePlaying = false;
  String? _errorMessage;
  // BoxShape _currentShape = BoxShape.circle; // resize full-screen tắt để không chặn kéo nút nổi

  @override
  void initState() {
    super.initState();

    // Native → overlay: cập nhật trạng thái pulse theo phát nhạc thực tế.
    _bridge.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPlaybackStarted':
          final type = call.arguments?.toString();
          if (mounted) {
            setState(() {
              _isGreetingPlaying = type == 'greeting';
              _isGoodbyePlaying = type == 'goodbye';
            });
          }
          break;
        case 'onPlaybackComplete':
          if (mounted) {
            setState(() {
              _isGreetingPlaying = false;
              _isGoodbyePlaying = false;
            });
          }
          break;
      }
      return null;
    });

    // Vẫn nghe kênh cũ (shareData từ app chính) để tương thích ngược.
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data['type'] == 'state_update') {
        setState(() {
          if (data['isGreetingPlaying'] != null) {
            _isGreetingPlaying = data['isGreetingPlaying'];
          }
          if (data['isGoodbyePlaying'] != null) {
            _isGoodbyePlaying = data['isGoodbyePlaying'];
          }
          if (data['errorMessage'] != null) {
            _showToast(data['errorMessage']);
          }
        });
      }
    });
  }

  void _showToast(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  /// Gọi bridge native. Trả về bool kết quả (true=đã phát, false=chưa cấu hình),
  /// hoặc null nếu bridge chưa sẵn sàng (đã fallback sang isolate chính).
  Future<bool?> _invokeBridge(String method) async {
    try {
      return await _bridge.invokeMethod<bool>(method);
    } on MissingPluginException {
      // Fallback: bridge chưa đăng ký → dùng đường cũ qua isolate chính.
      const map = {
        'playGreeting': 'play_greeting',
        'playGoodbye': 'play_goodbye',
        'stopAudio': 'stop_audio',
        'openApp': 'open_app',
      };
      _sendActionLegacy(map[method] ?? method);
      return null;
    } catch (e) {
      print('Overlay: lỗi gọi bridge [$method]: $e');
      return null;
    }
  }

  /// Đường cũ (dự phòng): gửi action qua IsolateNameServer tới app chính.
  Future<void> _sendActionLegacy(String action) async {
    try {
      final SendPort? sendPort =
          IsolateNameServer.lookupPortByName('overlay_action_port');
      if (sendPort != null) {
        sendPort.send({'action': action});
      }
    } catch (e) {
      print('Overlay: lỗi gửi action qua Isolate: $e');
    }
  }

  Future<void> _toggleGreeting() async {
    if (_isGreetingPlaying) {
      setState(() => _isGreetingPlaying = false);
      await _invokeBridge('stopAudio');
    } else {
      // Cập nhật lạc quan để phản hồi tức thì; native sẽ xác nhận lại qua callback.
      setState(() {
        _isGreetingPlaying = true;
        _isGoodbyePlaying = false;
      });
      final ok = await _invokeBridge('playGreeting');
      if (ok == false && mounted) {
        // Chưa cấu hình lời chào (native đã hiện Toast cho khách).
        setState(() => _isGreetingPlaying = false);
      }
    }
  }

  Future<void> _toggleGoodbye() async {
    if (_isGoodbyePlaying) {
      setState(() => _isGoodbyePlaying = false);
      await _invokeBridge('stopAudio');
    } else {
      setState(() {
        _isGoodbyePlaying = true;
        _isGreetingPlaying = false;
      });
      final ok = await _invokeBridge('playGoodbye');
      if (ok == false && mounted) {
        setState(() => _isGoodbyePlaying = false);
        _showToast('Chưa cấu hình lời tạm biệt');
      } else if (ok == null && mounted) {
        setState(() => _isGoodbyePlaying = false);
        _showToast('Không kết nối được native');
      }
    }
  }

  // Future<void> _openApp() async {
  //   await _invokeBridge('openApp');
  // }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: Stack(
        children: [
          // Glass
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.20),
                        Colors.white.withOpacity(0.06),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tap full-screen resize tắt — lớp này nuốt touch, khiến enableDrag native không kéo được.
          // Positioned.fill(
          //   child: GestureDetector(
          //     onTap: () async { ... },
          //     child: Container(color: Colors.transparent),
          //   ),
          // ),
          // 2. Buttons layer
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                // Nút mở app — tạm ẩn, chỉ giữ chào + tạm biệt.
                // Expanded(
                //   child: _buildNeonButton(
                //     icon: Icons.grid_view_rounded,
                //     iconColor: Colors.white,
                //     isGlow: false,
                //     onTap: _openApp,
                //   ),
                // ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 4,
              bottom: 4,
              right: 4,
              child: AnimatedOpacity(
                opacity: _errorMessage != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: ClipOval(
              child: Material(
                color: const Color(0xFF083C26),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isGlow
                        ? LinearGradient(
                            colors: [
                              _neonCyan.withOpacity(0.2),
                              _neonBlue.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: Border.all(
                      color:
                          isGlow ? _neonCyan : Colors.white.withOpacity(0.15),
                      width: 1.2,
                    ),
                  ),
                  child: _PulseWrapper(
                    key: ValueKey('pulse_$isGlow'),
                    isGlow: isGlow,
                    iconColor: iconColor,
                    child: Center(
                      key: ValueKey('icon_$isGlow'),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 30,
                        shadows: isGlow
                            ? [
                                Shadow(color: iconColor, blurRadius: 10),
                              ]
                            : null,
                      ),
                    ),
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

class _PulseWrapper extends StatefulWidget {
  final bool isGlow;
  final Color iconColor;
  final Widget child;

  const _PulseWrapper({
    super.key,
    required this.isGlow,
    required this.iconColor,
    required this.child,
  });

  @override
  State<_PulseWrapper> createState() => _PulseWrapperState();
}

class _PulseWrapperState extends State<_PulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isGlow) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlow != oldWidget.isGlow) {
      if (widget.isGlow) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isGlow) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _controller.value), // Icon to ra 10% theo nhịp
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.iconColor.withOpacity(0.5 * _controller.value),
                  blurRadius: 15 * _controller.value,
                  spreadRadius: 5 * _controller.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
