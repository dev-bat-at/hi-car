import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'overlay/overlay_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
    _initOverlayListener();
    WidgetsBinding.instance.addObserver(this);

    // Ensure overlay is hidden on startup
    _overlayProvider.hideOverlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _overlayProvider.hideOverlay();
    } else if (state == AppLifecycleState.paused) {
      _overlayProvider.showOverlay();
    }
  }

  // Listen for actions sent from overlay bubble
  void _initOverlayListener() {
    try {
      FlutterOverlayWindow.overlayListener.listen((data) {
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
            final action = data['action'];
            switch (action) {
              case 'play_greeting':
                _audioProvider.playGreetingViaNative();
                break;
              case 'play_goodbye':
                _audioProvider.playGoodbyeViaNative();
                break;
              case 'stop_audio':
                _audioProvider.stopNativeAudio();
                break;
              case 'open_app':
                ServiceChannel.instance.openApp();
                break;
            }
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
          );
        },
      ),
    );
  }
}
