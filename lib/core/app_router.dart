import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/gen_audio/gen_audio_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/setup/connection_mode_screen.dart';
import '../screens/setup/permission_config_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/gen-audio',
        builder: (context, state) => const GenAudioScreen(),
      ),
      GoRoute(
        path: '/connection-mode',
        builder: (context, state) {
          final fromSettings =
              state.uri.queryParameters['fromSettings'] == 'true';
          return ConnectionModeScreen(isFromSettings: fromSettings);
        },
      ),
      GoRoute(
        path: '/permission-config',
        builder: (context, state) {
          final fromSettings =
              state.uri.queryParameters['fromSettings'] == 'true';
          return PermissionConfigScreen(isFromSettings: fromSettings);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
