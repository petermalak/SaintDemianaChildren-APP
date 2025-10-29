import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/di/service_locator.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/notification_listener_wrapper.dart';
import 'features/splash_screen/view/screen/splash_screen.dart';
import 'features/authentication/view/screen/login_screen.dart';
import 'features/super_admin_&_khadem_layout/home/view/screen/super_admin_&_khadem_main_screen.dart';
import 'features/makhdoum_layout/home/view/screen/makhdoum_main_screen.dart';
import 'features/super_admin_&_khadem_layout/super_admin/class_management/view/screen/class_management_screen.dart';
import 'features/profile/view/screen/profile_screen.dart';
import 'features/profile/repository/i_profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on mobile platforms (not web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized for mobile');

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      print('⚠️ Firebase initialization failed: $e');
    }
  } else {
    print(
        'ℹ️ Web platform detected - skipping Firebase initialization (use mobile app for notifications)');
  }

  runApp(const SaintDemianaApp());
}

class SaintDemianaApp extends StatefulWidget {
  const SaintDemianaApp({super.key});

  @override
  State<SaintDemianaApp> createState() => _SaintDemianaAppState();
}

class _SaintDemianaAppState extends State<SaintDemianaApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 [main] Starting app initialization...');

    // Initialize Hive storage
    await StorageService().init();
    print('✅ [main] Storage initialized');

    // Setup dependency injection
    await setupServiceLocator();
    print('✅ [main] Services registered');

    // Load user from storage BEFORE app shows
    // This ensures the user/token is available for all API calls
    print('🚀 [main] Loading user from storage...');
    await sl<IProfileRepository>().loadUser();
    print('✅ [main] User loaded');

    setState(() {
      _initialized = true;
    });

    print('✅ [main] App initialization complete!');
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Show loading screen while initializing
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B1538), Color(0xFFC41E3A)],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      locale: const Locale('ar', 'EG'),
      title: 'Saint Demiana Church',
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: NotificationListenerWrapper(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/khadem',
      builder: (context, state) => const KhademMainScreen(),
    ),
    GoRoute(
      path: '/makhdoum',
      builder: (context, state) => const MakhdoumMainScreen(),
    ),
    GoRoute(
      path: '/class-management',
      builder: (context, state) {
        return const MainClassManagementScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),
  ],
);
