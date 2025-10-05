import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'di/service_locator.dart';
import 'theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/class_provider.dart';
import '../features/splash_screen/view/screen/splash_screen.dart';
import '../features/authentication/view/screen/login_screen.dart';
import '../features/super_admin_&_khadem_layout/home/view/screen/super_admin_&_khadem_main_screen.dart';
import '../features/makhdoum_layout/home/view/screen/makhdoum_main_screen.dart';
import '../screens/class_management_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../features/profile/view/screen/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const SaintDemianaApp());
}

class SaintDemianaApp extends StatelessWidget {
  const SaintDemianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
      ],
      child: MaterialApp.router(
        locale: const Locale('ar', 'EG'),
        title: 'Saint Demiana Children',
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
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
      builder: (context, state) => const ClassManagementScreen(),
    ),
    GoRoute(
      path: '/super-super_admin-dashboard',
      builder: (context, state) => const SuperAdminDashboard(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),
  ],
);
