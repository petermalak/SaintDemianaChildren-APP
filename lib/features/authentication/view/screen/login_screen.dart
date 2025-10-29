import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/authentication/viewmodel/login_cubit.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/interface/i_notification_service.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../notifications/repository/i_notification_repository.dart';
import '../../model/user_model.dart';
import '../../repository/i_authentication_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _formSlide;
  late Animation<double> _formOpacity;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _formSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );

    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _backgroundController.forward();
    await _logoController.forward();
    await _formController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Initialize notifications after successful login
  Future<void> _initializeNotifications() async {
    try {
      print('🔔 Initializing notifications after login...');

      // Get notification service
      final notificationService = sl<INotificationService>();

      // Initialize notification service
      await notificationService.initialize();

      // Get FCM token
      final fcmToken = await notificationService.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('✅ FCM Token received: ${fcmToken.substring(0, 20)}...');

        // Send FCM token to backend
        final notificationRepository = sl<INotificationRepository>();
        final result = await notificationRepository.updateFcmToken(fcmToken);

        result.fold(
          (error) {
            print('❌ Failed to update FCM token on server: $error');
          },
          (_) {
            print('✅ FCM token updated on server successfully');
          },
        );
      } else {
        print('⚠️ No FCM token received');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryCream.withValues(
                      alpha: _backgroundOpacity.value.clamp(0.0, 1.0)),
                  AppColors.backgroundCard.withValues(
                      alpha: _backgroundOpacity.value.clamp(0.0, 1.0)),
                  AppColors.accentGold.withValues(
                      alpha: 0.1 * _backgroundOpacity.value.clamp(0.0, 1.0)),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 500,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogoSection(context),
                        SizedBox(
                            height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                        _buildFormSection(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final logoSize = isMobile ? 120.0 : 140.0;

    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Column(
              children: [
                // Enhanced Logo Container
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMaroon
                            .withValues(alpha: 0.3.clamp(0.0, 1.0)),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.accentGold
                            .withValues(alpha: 0.2.clamp(0.0, 1.0)),
                        blurRadius: 35,
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
                            size: logoSize * 0.6,
                            color: AppColors.accentGold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                // App Title with enhanced styling
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard
                        .withValues(alpha: 0.9.clamp(0.0, 1.0)),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: AppColors.accentGold
                          .withValues(alpha: 0.4.clamp(0.0, 1.0)),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMaroon
                            .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Saint Demiana Church',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.primaryMaroon,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 24 : 28,
                              letterSpacing: 0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'كنيسة القديسة دميانة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 18 : 22,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: 80,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryMaroon,
                              AppColors.accentGold
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return BlocProvider(
      create: (context) => LoginCubit(sl<IAuthenticationRepository>()),
      child: AnimatedBuilder(
        animation: _formController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _formSlide.value),
            child: Opacity(
              opacity: _formOpacity.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMaroon
                          .withValues(alpha: 0.2.clamp(0.0, 1.0)),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.accentGold
                          .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                      blurRadius: 30,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'مرحباً بك',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primaryMaroon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 20 : 24,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: AppSpacing.md,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'البريد الإلكتروني',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        onSubmit: (_) => _passwordFocusNode.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.md : AppSpacing.lg),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'كلمة المرور',
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        focusNode: _passwordFocusNode,
                        onSubmit: (_) {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.read<LoginCubit>().login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                      BlocConsumer<LoginCubit, LoginState>(
                        listener: (context, state) {
                          if (state is LoginFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                                margin: const EdgeInsets.all(AppSpacing.md),
                              ),
                            );
                          } else if (state is LoginSuccess) {
                            // Initialize notifications after successful login
                            _initializeNotifications();

                            final currentUser = state.user;
                            switch (currentUser.role!) {
                              case UserRole.khadem:
                                context.go('/khadem');
                                break;
                              case UserRole.makhdoum:
                                context.go('/makhdoum');
                                break;
                              case UserRole.superAdmin:
                                context.go('/khadem');
                                break;
                            }
                          }
                        },
                        builder: (context, state) {
                          if (state is LoginLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return SubmitButton(
                            onPressed: () => {
                              if (_formKey.currentState?.validate() ?? false)
                                {
                                  context.read<LoginCubit>().login(
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                      ),
                                }
                            },
                            text: 'تسجيل الدخول',
                          );
                        },
                      ),

                      // Login Button
                      SizedBox(
                          height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                      // Help Text
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold
                              .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.accentGold
                                .withValues(alpha: 0.3.clamp(0.0, 1.0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primaryMaroon,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Need help? Contact your church administrator',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: AppSpacing.sm,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
