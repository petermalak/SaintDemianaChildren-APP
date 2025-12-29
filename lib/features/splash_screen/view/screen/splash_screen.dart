import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../authentication/model/user_model.dart';
import '../../../profile/repository/i_profile_repository.dart';
import '../../../authentication/view/widget/role_selection_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textSlide;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _textSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();

    await _textController.forward();

    await _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));

    _checkAuthentication();
  }

  void _checkAuthentication() async {
    // sl<IProfileRepository>().user = UserModel(
    //     id: "1",
    //     role: UserRole.superAdmin,
    //     name: "felo",
    //     token:
    //         "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjA0OTBlOTk3LWQ5N2QtNDhlNC04NzFlLTQyYjhmM2FhNGU0ZSIsIm5hbWUiOiJTdXBlciBBZG1pbiIsImVtYWlsIjoic3VwZXJhZG1pbkB0ZXN0LmNvbSIsInBob25lTnVtYmVyIjoiKzEyMzQ1Njc4OTAiLCJyb2xlIjoic3VwZXJfYWRtaW4iLCJwcm9maWxlSW1hZ2UiOm51bGwsInBhc3N3b3JkSGFzaCI6IiQyYiQxMCRTdWZEdy51cjVHM0dXVEtleGVPR1JPaXY1aUouODZmRmQ5aGguRC50S3VoQUZabEQ4U0NycSIsImZhdGhlcnNQaG9uZU51bWJlciI6bnVsbCwibW90aGVyc1Bob25lTnVtYmVyIjpudWxsLCJiaXJ0aGRhdGUiOm51bGwsImFkZHJlc3MiOiIxMjMgU3VwZXIgQWRtaW4gU3QiLCJhZGRyZXNzTG9jYXRpb25MaW5rIjpudWxsLCJmYXRoZXJPZkNvbmZlc3Npb24iOm51bGwsImNyZWF0ZWRBdCI6IjIwMjUtMTAtMDFUMTE6NTE6MjAuMDAwWiIsInVwZGF0ZWRBdCI6IjIwMjUtMTAtMDFUMTE6NTE6MjAuMDAwWiIsImlhdCI6MTc1OTg0MzMyMSwiZXhwIjoxNzYwNDQ4MTIxfQ.S3HoTHbZ8HhsPgFNmz_UZJJP8vcPR2MHeW8iS0LD-KM",
    //     email: "superAdmin@test.com");
    // Note: Storage already initialized in main.dart, no need to init again
    print('🚀 [SplashScreen] Starting authentication check...');
    await sl<IProfileRepository>().loadUser().then((user) async {
      if (user != null) {
        // Check if user has multiple roles
        final hasMixedRoles = RoleHelper.hasMixedRoles(user);
        
        if (hasMixedRoles) {
          // Show role selection dialog for users with multiple roles
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false, // User must choose
              builder: (dialogContext) => RoleSelectionDialog(
                user: user,
                onRoleSelected: (selectedRole) async {
                  // Navigate based on selected role
                  if (selectedRole == UserRole.khadem || selectedRole == UserRole.superAdmin) {
                    final result = await sl<IMembersRepository>().fetchMembers(
                      selectedRole == UserRole.superAdmin,
                    );
                    
                    result.fold(
                      (failure) {
                        _showErrorDialog(failure);
                      },
                      (_) {
                        context.go('/khadem');
                      },
                    );
                  } else if (selectedRole == UserRole.makhdoum) {
                    context.go('/makhdoum');
                  }
                },
              ),
            );
          });
        } else {
          // Single role - navigate directly
          final primaryRole = RoleHelper.getPrimaryRole(user);
          
          if (primaryRole == UserRole.khadem || primaryRole == UserRole.superAdmin) {
            final result = await sl<IMembersRepository>().fetchMembers(
              primaryRole == UserRole.superAdmin,
            );

            result.fold(
              (failure) {
                _showErrorDialog(failure);
              },
              (_) {
                context.go('/khadem');
              },
            );
          } else if (primaryRole == UserRole.makhdoum) {
            context.go('/makhdoum');
          } else {
            context.go('/login');
          }
        }
      } else {
        context.go('/login');
      }
    });
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'خطأ في التحميل',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حدث خطأ أثناء تحميل البيانات:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppColors.error.withValues(alpha: 0.05.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        AppColors.error.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: const Text('إعادة تسجيل الدخول'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (Theme.of(context).platform == TargetPlatform.android) {
                    SystemNavigator.pop();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.accentWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('إغلاق التطبيق'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value * 0.1,
                        child: Container(
                          width: isMobile ? 120 : 150,
                          height: isMobile ? 120 : 150,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryMaroon
                                    .withValues(alpha: 0.3.clamp(0.0, 1.0)),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AppColors.accentGold
                                    .withValues(alpha: 0.2.clamp(0.0, 1.0)),
                                blurRadius: 30,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryMaroon,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.church,
                                    size: isMobile ? 60 : 80,
                                    color: AppColors.accentGold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(
                        children: [
                          Text(
                            'Saint Demiana Church',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: AppColors.primaryMaroon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 24 : 32,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'كنيسة القديسة دميانة',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 18 : 24,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryMaroon,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Loading...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: AppSpacing.sm,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
