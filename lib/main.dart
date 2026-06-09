import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hi_car/core/app_colors.dart';
import 'package:hi_car/overlay/overlay_main.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/constants.dart';
import 'native/service_channel.dart';
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
  DartPluginRegistrant.ensureInitialized();
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
  late final SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = AudioProvider()..init();
    _overlayProvider = OverlayProvider()..init();
    _settingsProvider = SettingsProvider()..init();

    // Listen to audio provider to sync state to overlay
    _audioProvider.addListener(_updateOverlayState);

    // 🟢 Chế độ Android Màn Độ: Khi phát xong thì thu nhỏ app
    _audioProvider.onNativePlaybackComplete = () {
      if (_settingsProvider.connectionMode == 'android_screen_mode') {
        debugPrint(
            'Main: Audio finished in android_screen_mode, minimizing app...');
        ServiceChannel.instance.minimizeApp();
      }
    };

    _initOverlayListener();
    _initIsolateListener();
    WidgetsBinding.instance.addObserver(this);

    // 🟢 Chế độ Mở App là Chào: Phát nhạc ngay khi khởi động
    _initPlayOnOpen();

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
        debugPrint('Main: Triggering openApp');
        await _openAppDirect();
        break;
    }

    if (!success && errorMsg != null) {
      _overlayProvider.updateOverlayState(errorMessage: errorMsg);
    }
  }

  /// Bring the app to the foreground.
  ///
  /// The native `triggerOpenApp` launches the main Activity with
  /// FLAG_ACTIVITY_NEW_TASK | CLEAR_TOP | SINGLE_TOP.
  ///
  /// With `shouldDestroyEngineWithHost() = false` in MainActivity,
  /// the FlutterEngine (and its MethodChannels) survive Activity
  /// destruction, so the service channel should always be available.
  Future<void> _openAppDirect() async {
    // Close overlay so it doesn't stay on top
    try {
      await _overlayProvider.hideOverlay();
    } catch (_) {}

    // Try available channels to launch the Activity
    for (final channelName in [
      AppConstants.serviceChannel,
      AppConstants.bluetoothChannel,
    ]) {
      try {
        final channel = MethodChannel(channelName);
        final result = await channel.invokeMethod('openApp');
        debugPrint('Main: openApp via $channelName → $result');
        return;
      } on MissingPluginException {
        debugPrint('Main: openApp – $channelName unavailable');
      } catch (e) {
        debugPrint('Main: openApp – $channelName error: $e');
      }
    }

    // Ultimate fallback: re-init ServiceChannel and try once more
    debugPrint(
        'Main: All channels unavailable, re-initializing ServiceChannel');
    try {
      ServiceChannel.instance.init();
      await ServiceChannel.instance.openApp();
    } catch (e) {
      debugPrint('Main: openApp final fallback failed: $e');
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

  // 🟢 Logic phát nhạc khi vừa mở app
  bool _hasTriggeredOpenGreeting = false;

  Future<void> _initPlayOnOpen() async {
    if (_hasTriggeredOpenGreeting) return;

    // Đợi Settings load xong
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_settingsProvider.playOnOpen) {
      // Đợi thêm cho AudioProvider load xong danh sách nhạc từ local/server
      int retryCount = 0;
      while (_audioProvider.audioList.isEmpty && retryCount < 10) {
        debugPrint('Main: Audio list empty, waiting... ($retryCount)');
        await Future.delayed(const Duration(milliseconds: 1000));
        retryCount++;
      }

      if (_audioProvider.audioList.isNotEmpty) {
        debugPrint('Main: Triggering play greeting on open...');
        _hasTriggeredOpenGreeting = true;
        await _audioProvider.playGreetingViaNative();
      } else {
        debugPrint(
            'Main: Could not trigger greeting - list still empty after 10s');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => _audioProvider),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()..init()),
        ChangeNotifierProvider(create: (_) => _overlayProvider),
        ChangeNotifierProvider(create: (_) => _settingsProvider),
        ChangeNotifierProvider(
            create: (_) => PermissionProvider()..checkAllPermissions()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final Size dynamicDesignSize =
              width > 600 ? Size(width, height) : const Size(390, 844);
          return ScreenUtilInit(
            designSize: dynamicDesignSize,
            minTextAdapt: true,
            splitScreenMode: true,
            useInheritedMediaQuery: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Giọng Thương Gia',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                routerConfig: AppRouter.router,
                builder: EasyLoading.init(),
              );
            },
          );
        },
      ),
    );
  }
}
