import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/data_refresh_cubit.dart';
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

    // Kept short on purpose: the animations run before the app decides where to go.
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _startStartup();
  }

  /// Load the saved session while the logo animates so the user is not waiting twice.
  void _startStartup() async {
    UserModel? user;
    Future<void> loadUser() async {
      user = await sl<IProfileRepository>().loadUser();
    }

    _fadeController.forward();
    await Future.wait<void>([
      _logoController.forward(),
      _textController.forward(),
      loadUser(),
    ]);
    if (!mounted) return;
    _navigateForUser(user);
  }

  void _navigateForUser(UserModel? user) {
    if (user == null) {
      context.go('/login');
      return;
    }

    if (RoleHelper.hasMixedRoles(user)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => RoleSelectionDialog(
            user: user,
            onRoleSelected: (selectedRole) async {
              if (selectedRole == UserRole.khadem ||
                  selectedRole == UserRole.superAdmin) {
                _openKhademLayout(selectedRole);
              } else if (selectedRole == UserRole.makhdoum) {
                context.go('/makhdoum');
              }
            },
          ),
        );
      });
      return;
    }

    final primaryRole = RoleHelper.getPrimaryRole(user);
    if (primaryRole == UserRole.khadem || primaryRole == UserRole.superAdmin) {
      _openKhademLayout(primaryRole);
    } else if (primaryRole == UserRole.makhdoum) {
      context.go('/makhdoum');
    } else {
      context.go('/login');
    }
  }

  /// Opens the servant layout straight away. The members list (hundreds of records)
  /// loads in the background, and each screen shows its own loading state.
  void _openKhademLayout(UserRole? role) {
    context.go('/khadem');
    sl<IMembersRepository>()
        .fetchMembers(role == UserRole.superAdmin)
        .then((result) => result.fold(
              (error) => debugPrint('⚠️ [SplashScreen] Members preload: $error'),
              (_) => sl<DataRefreshCubit>().refreshMembers(),
            ));
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
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
                            'جاري التحميل...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
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
    ),
    );
  }
}
