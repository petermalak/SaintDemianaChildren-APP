import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Temporarily disabled - will be fixed in next update
// import 'package:saint_demiana_children/core/services/shorebird_code_push_stub.dart'
//     if (dart.library.io) 'package:shorebird_code_push/shorebird_code_push.dart';

import 'core/di/service_locator.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/notification_listener_wrapper.dart';
import 'core/widgets/update_checker.dart';
import 'features/splash_screen/view/screen/splash_screen.dart';
import 'features/authentication/view/screen/login_screen.dart';
import 'features/super_admin_&_khadem_layout/home/view/screen/super_admin_&_khadem_main_screen.dart';
import 'features/makhdoum_layout/home/view/screen/makhdoum_main_screen.dart';
import 'features/super_admin_&_khadem_layout/super_admin/class_management/view/screen/class_management_screen.dart';
import 'features/profile/view/screen/profile_screen.dart';
import 'features/profile/repository/i_profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (e.g. in release) so we don't show raw exception
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint(details.stack?.toString());
    }
  };

  // Initialize Firebase only on mobile platforms (not web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('✅ Firebase initialized for mobile');
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firebase initialization failed: $e');
      }
    }
  } else {
    if (kDebugMode) {
      print(
          'ℹ️ Web platform detected - skipping Firebase initialization (use mobile app for notifications)');
    }
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

  /// Non-null if initialization failed (prevents crash, shows error UI with retry).
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    setState(() {
      _initError = null;
    });
    if (kDebugMode) {
      print('🚀 [main] Starting app initialization...');
    }

    try {
      // Initialize Hive storage (can throw on some devices if storage unavailable/corrupted)
      try {
        await StorageService().init();
      } catch (e) {
        if (kDebugMode) print('❌ [main] Storage init failed: $e');
        throw Exception(
            'تعذر تهيئة التخزين المحلي. حاول مرة أخرى أو أعد تثبيت التطبيق.');
      }
      if (kDebugMode) {
        print('✅ [main] Storage initialized');
      }

      // Setup dependency injection
      await setupServiceLocator();
      if (kDebugMode) {
        print('✅ [main] Services registered');
      }

      // Load user from storage BEFORE app shows
      if (kDebugMode) {
        print('🚀 [main] Loading user from storage...');
      }
      await sl<IProfileRepository>().loadUser();
      if (kDebugMode) {
        print('✅ [main] User loaded');
      }

      if (!mounted) return;
      setState(() {
        _initialized = true;
      });

      if (kDebugMode) {
        print('✅ [main] App initialization complete!');
      }

      // Check for updates after initialization (non-blocking)
      if (!kIsWeb) {
        _checkForUpdates();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [main] Init failed: $e');
        print(stack);
      }
      if (!mounted) return;
      setState(() {
        _initError = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'حدث خطأ عند فتح التطبيق. حاول مرة أخرى.';
      });
    }
  }

  /// Checks for app updates in the background
  Future<void> _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      final result = await updateService.checkForUpdate();

      result.fold(
        (error) {
          if (kDebugMode) {
            print('⚠️ [main] Update check failed: $error');
          }
        },
        (updateInfo) {
          if (updateInfo.isUpdateAvailable) {
            if (kDebugMode) {
              print(
                  '📦 [main] Update available: force=${updateInfo.isForceUpdate}');
            }
            // Show update dialog if update is available
            // This will be handled by the update service
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [main] Error checking for updates: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Init failed: show error and retry (avoids crash on deployed/release builds)
    if (_initError != null) {
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.white70),
                    const SizedBox(height: 24),
                    Text(
                      _initError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _initializeApp(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('حاول مرة أخرى'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8B1538),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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

    return UpdateChecker(
      child: MaterialApp.router(
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
      ),
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
