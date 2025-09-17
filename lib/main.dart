import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/login_screen.dart';
import 'screens/khadem_enhanced_screen.dart';
import 'screens/makhdoum_enhanced_screen.dart';

void main() {
  runApp(const SaintDemianaApp());
}

class SaintDemianaApp extends StatelessWidget {
  const SaintDemianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp.router(
        title: 'Saint Demiana Children',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/khadem',
      builder: (context, state) => const KhademEnhancedScreen(),
    ),
    GoRoute(
      path: '/makhdoum',
      builder: (context, state) => const MakhdoumEnhancedScreen(),
    ),
  ],
);