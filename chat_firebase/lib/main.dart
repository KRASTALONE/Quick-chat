import 'package:chatappui/core/constants/app_strings.dart';
import 'package:chatappui/data/services/notification_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/firebase_options.dart';
import 'package:chatappui/presentation/screens/auth/login_screen.dart';
import 'package:chatappui/presentation/screens/home/bottom_nav_screen.dart';
import 'package:chatappui/presentation/screens/splash/splash_screen.dart';
import 'package:chatappui/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          navigatorKey: NotificationService.navigatorKey,
          theme: themeProvider.themeData,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(themeProvider.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppStartupScreen(),
        );
      },
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await context.read<ThemeProvider>().loadPreferences();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    OneSignal.initialize("2025c683-6eef-42b6-9999-ec765b2bdee8");

    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      event.notification.display();
    });

    await NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'App failed to start.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return const AuthenticatedShell(child: BottomNavScreen());
        }

        return const LoginScreen();
      },
    );
  }
}

class AuthenticatedShell extends StatefulWidget {
  final Widget child;

  const AuthenticatedShell({super.key, required this.child});

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell>
    with WidgetsBindingObserver {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineAndSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userService.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnlineAndSync();
        break;
      default:
        _userService.setOffline();
        break;
    }
  }

  Future<void> _setOnlineAndSync() async {
    await _userService.setOnline();
    await NotificationService.instance.syncTokenForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}