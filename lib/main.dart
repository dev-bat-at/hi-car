import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hi_car/core/app_colors.dart';
import 'package:hi_car/overlay/overlay_main.dart';
import 'native/service_channel.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/overlay_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/permission_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupEasyLoading();
  runApp(const MyApp());
}

void _setupEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 16.0
    ..progressColor = AppColors.primary
    ..backgroundColor = AppColors.surface
    ..indicatorColor = AppColors.primary
    ..textColor = AppColors.textPrimary
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

// Register overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AudioProvider _audioProvider;
  late final OverlayProvider _overlayProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = AudioProvider()..init();
    _overlayProvider = OverlayProvider()..init();

    // Listen to audio provider to sync state to overlay
    _audioProvider.addListener(_updateOverlayState);

    _initOverlayListener();
    _initIsolateListener();
    WidgetsBinding.instance.addObserver(this);

    // Ensure overlay is hidden on startup
    _overlayProvider.hideOverlay();
  }

  void _updateOverlayState() {
    _overlayProvider.updateOverlayState(
      isGreetingPlaying: _audioProvider.isNativeGreetingPlaying,
      isGoodbyePlaying: _audioProvider.isNativeGoodbyePlaying,
    );
  }

  @override
  void dispose() {
    _audioProvider.removeListener(_updateOverlayState);
    IsolateNameServer.removePortNameMapping('overlay_action_port');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _overlayProvider.hideOverlay();
    } else if (state == AppLifecycleState.paused) {
      _overlayProvider.showOverlay().then((_) {
        _updateOverlayState();
      });
    }
  }

  void _initIsolateListener() {
    final receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping('overlay_action_port');
    IsolateNameServer.registerPortWithName(
        receivePort.sendPort, 'overlay_action_port');

    receivePort.listen((message) {
      debugPrint('Isolate listener received: $message');
      if (message is Map && message.containsKey('action')) {
        _handleOverlayAction(message['action']);
      }
    });
  }

  Future<void> _handleOverlayAction(dynamic action) async {
    OverlayDebugStore.record('Action received: $action');
    bool success = true;
    String? errorMsg;

    switch (action) {
      case 'play_greeting':
        success = await _audioProvider.playGreetingViaNative();
        if (!success) errorMsg = 'Chưa chọn nhạc chào';
        break;
      case 'play_goodbye':
        success = await _audioProvider.playGoodbyeViaNative();
        if (!success) errorMsg = 'Chưa chọn nhạc tạm biệt';
        break;
      case 'stop_audio':
        await _audioProvider.stopNativeAudio();
        break;
      case 'open_app':
        debugPrint('Main: Triggering openApp via ServiceChannel');
        ServiceChannel.instance.openApp();
        break;
    }

    if (!success && errorMsg != null) {
      _overlayProvider.updateOverlayState(errorMessage: errorMsg);
    }
  }

  // Listen for actions sent from overlay bubble
  void _initOverlayListener() {
    try {
      FlutterOverlayWindow.overlayListener.listen((data) {
        debugPrint('Overlay listener received: $data');
        if (data is Map) {
          final type = data['type'];

          if (type == 'overlay_error') {
            final message =
                (data['message'] ?? 'Unknown overlay error').toString();
            OverlayDebugStore.record(message);
            debugPrint('Overlay error: $message');
            return;
          }

          if (data.containsKey('action')) {
            _handleOverlayAction(data['action']);
          }
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => _audioProvider),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()..init()),
        ChangeNotifierProvider(create: (_) => _overlayProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(
            create: (_) => PermissionProvider()..checkAllPermissions()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Giọng Thương Gia',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: AppRouter.router,
            builder: EasyLoading.init(),
          );
        },
      ),
    );
  }
}
