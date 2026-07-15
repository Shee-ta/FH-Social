import 'package:flutter/material.dart';
import 'package:frontend/UI/app_colors.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/backend_url_settings_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/connection_services/sse_listener_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> rootNavigatorKey =
  GlobalKey<NavigatorState>();

class FHSocialApp extends StatefulWidget {
  const FHSocialApp({super.key});

  @override
  State<FHSocialApp> createState() => _FHSocialAppState();
}

class _FHSocialAppState extends State<FHSocialApp> {
  final _di = AppDI.instance;

  late final AuthController _authController;
  late final SseListenerService _sseListenerService;

  _FHSocialAppState() {
    _authController = _di.authController;
    _sseListenerService = _di.sseListenerService;
  }


  @override
  void initState() {
    super.initState();
    _sseListenerService.startListening();
    _authController.restoreSession();
  }

  @override
  void dispose() {
    _sseListenerService.stopListening();
    super.dispose();
  }

  ThemeData _appTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _di.settingsService.themeColor,
      brightness: _di.settingsService.themeBrightness,
    );

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    RoundedRectangleBorder buttonShape() =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    const buttonPadding =
        EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ThemeData(
      colorScheme: colorScheme,
      extensions: const [
        AppColors(
          success: Color.fromARGB(255, 25, 83, 27),
          successOutline: Color.fromARGB(255, 40, 100, 43),
          onSuccess: Color(0xFFFFFFFF),
        ),
      ],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(Colors.transparent, 0),
        enabledBorder: border(Colors.transparent, 0),
        focusedBorder: border(colorScheme.primary, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _authController,
        _di.settingsService,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'FH Social',
          debugShowCheckedModeBanner: false,
          theme: _appTheme(),
          initialRoute: MainScreen.routeName,
          onGenerateRoute: (settings) {
            return _guardedRoute(settings, _authController);
          },
        );
      },
    );
  }
}

PageRoute<void> _guardedRoute(
  RouteSettings settings,
  AuthController authController,
) {
  final routeName = settings.name ?? MainScreen.routeName;

  switch (routeName) {
    case LoginScreen.routeName:
      if (authController.isLoggedIn) {
        return _pageRoute(
          direction: Direction.right,
          settings: const RouteSettings(name: MainScreen.routeName),
          child: MainScreen(),
        );
      }
      return _pageRoute(
        direction: Direction.right,
        settings: const RouteSettings(name: LoginScreen.routeName),
        child: LoginScreen(),
      );

    case MainScreen.routeName:
      return _pageRoute(
        direction: Direction.left,
        settings: const RouteSettings(name: MainScreen.routeName),
        child: MainScreen(),
      );

    case SettingsScreen.routeName:
      return _pageRoute(
        direction: Direction.left,
        settings: const RouteSettings(name: SettingsScreen.routeName),
        child: SettingsScreen(),
      );

    case BackendUrlSettingsScreen.routeName:
      return _pageRoute(
        direction: Direction.left,
        settings: const RouteSettings(name: BackendUrlSettingsScreen.routeName),
        child: BackendUrlSettingsScreen(),
      );

    default:
      return _pageRoute(
        direction: Direction.left,
        settings: const RouteSettings(name: MainScreen.routeName),
        child: MainScreen(),
      );
  }
}
enum Direction {
  left,
  right,
  up,
  down,
}

PageRoute<void> _pageRoute({
  required RouteSettings settings,
  required Widget child,
  required Direction direction,
}) {
  return PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (_, _, _) => child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (_, animation, _, routeChild) {
      Offset begin;
      switch (direction) {
        case Direction.left:
          begin = const Offset(-1.0, 0.0);
          break;
        case Direction.right:
          begin = const Offset(1.0, 0.0);
          break;
        case Direction.up:
          begin = const Offset(0.0, -1.0);
          break;
        case Direction.down:
          begin = const Offset(0.0, 1.0);
          break;
      }
      
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final tween = Tween<Offset>(begin: begin, end: end)
          .chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: routeChild,
      );
    },
  );
}
