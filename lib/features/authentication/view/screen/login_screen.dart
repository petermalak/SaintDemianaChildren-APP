import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:saint_demiana_children/features/authentication/viewmodel/login_cubit.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/interface/i_notification_service.dart';
import '../../../../core/services/interface/i_biometric_service.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../notifications/repository/i_notification_repository.dart';
import '../../model/user_model.dart';
import '../../repository/i_authentication_repository.dart';
import '../widget/role_selection_dialog.dart';

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

  bool _biometricAvailable = false;
  bool _checkingBiometric = true;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _formSlide;
  late Animation<double> _formOpacity;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _initializeBiometricState();
  }

  /// Initializes all animation controllers and animations.
  void _initializeAnimations() {
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
  }

  /// Starts the login screen animations in sequence.
  Future<void> _startAnimations() async {
    _backgroundController.forward();
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _formController.forward();
  }

  /// Initializes biometric authentication state.
  void _initializeBiometricState() {
    if (kIsWeb) {
      _biometricAvailable = false;
      _checkingBiometric = false;
    } else {
      // On mobile, start with checking state
      _checkingBiometric = true;
      _biometricAvailable = false;
    }
  }

  /// Checks if biometric authentication is available and ready to use.
  /// 
  /// This method is called after the LoginCubit is created to check
  /// if biometric login should be displayed to the user.
  Future<void> _checkBiometricAvailability(BuildContext context) async {
    if (kIsWeb || !mounted) {
      _updateBiometricState(false, false);
      return;
    }

    try {
      if (kDebugMode) {
        print('🔍 [LoginScreen] Checking biometric availability...');
      }
      final biometricService = sl<IBiometricService>();
      
      if (!biometricService.isSupported) {
        if (kDebugMode) {
          print('❌ [LoginScreen] Biometric not supported on this platform');
        }
        _updateBiometricState(false, false);
        return;
      }

      if (kDebugMode) {
        print('✅ [LoginScreen] Biometric is supported, checking availability...');
      }
      final isAvailable = await biometricService.isAvailable();
      if (kDebugMode) {
        print('📱 [LoginScreen] Biometric available: $isAvailable');
      }
      
      if (!isAvailable) {
        if (kDebugMode) {
          print('❌ [LoginScreen] Biometric not available on device');
        }
        _updateBiometricState(false, false);
        return;
      }

      final hasCredentials = await biometricService.hasSavedCredentials();
      if (kDebugMode) {
        print('🔐 [LoginScreen] Has saved credentials: $hasCredentials');
      }
      
      if (!hasCredentials) {
        if (kDebugMode) {
          print('⚠️ [LoginScreen] No saved credentials - user needs to login first');
        }
        _updateBiometricState(false, false);
        return;
      }

      if (kDebugMode) {
        print('✅ [LoginScreen] Biometric login is available!');
      }
      _updateBiometricState(true, false);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [LoginScreen] Error checking biometric: $e');
        print('❌ [LoginScreen] StackTrace: $stackTrace');
      }
      // Log error but don't show to user - biometric is optional
      _updateBiometricState(false, false);
    }
  }

  /// Updates the biometric availability state safely.
  void _updateBiometricState(bool available, bool checking) {
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _checkingBiometric = checking;
    });
  }

  /// Builds the biometric login section with divider and button.
  Widget _buildBiometricLoginSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        SizedBox(height: AppSpacing.md),
        _buildDivider(context),
        SizedBox(height: AppSpacing.md),
        _buildBiometricLoginButton(context, isMobile),
      ],
    );
  }

  /// Builds the divider with "أو" (or) text.
  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'أو',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Builds the biometric login button.
  Widget _buildBiometricLoginButton(BuildContext context, bool isMobile) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        return OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () => context.read<LoginCubit>().loginWithBiometrics(),
          icon: Icon(
            Icons.fingerprint,
            color: isLoading
                ? AppColors.textSecondary
                : AppColors.primaryMaroon,
          ),
          label: Text(
            'تسجيل الدخول بالبصمة',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isLoading
                      ? AppColors.textSecondary
                      : AppColors.primaryMaroon,
                  fontWeight: FontWeight.w600,
                ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
              horizontal: AppSpacing.lg,
            ),
            side: BorderSide(
              color: isLoading
                  ? AppColors.textSecondary.withValues(alpha: 0.3)
                  : AppColors.primaryMaroon,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      },
    );
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
      create: (context) {
        final cubit = LoginCubit(
          sl<IAuthenticationRepository>(),
          sl<IBiometricService>(),
        );
        // Check biometric availability after cubit is created and widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Use the context from the widget tree that has the cubit
            final cubitContext = context;
            _checkBiometricAvailability(cubitContext);
          }
        });
        return cubit;
      },
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
                            
                            // Check if user has multiple roles
                            final hasMixedRoles = RoleHelper.hasMixedRoles(currentUser);
                            
                            if (hasMixedRoles) {
                              // Show role selection dialog for users with multiple roles
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false, // User must choose
                                  builder: (dialogContext) => RoleSelectionDialog(
                                    user: currentUser,
                                    onRoleSelected: (selectedRole) {
                                      // Navigate based on selected role
                                      switch (selectedRole) {
                                        case UserRole.khadem:
                                        case UserRole.superAdmin:
                                          context.go('/khadem');
                                          break;
                                        case UserRole.makhdoum:
                                          context.go('/makhdoum');
                                          break;
                                      }
                                    },
                                  ),
                                );
                              });
                            } else {
                              // Single role - navigate directly
                              final primaryRole = RoleHelper.getPrimaryRole(currentUser);
                              
                              switch (primaryRole) {
                                case UserRole.khadem:
                                case UserRole.superAdmin:
                                  context.go('/khadem');
                                  break;
                                case UserRole.makhdoum:
                                  context.go('/makhdoum');
                                  break;
                                default:
                                  context.go('/login');
                                  break;
                              }
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

                      // Biometric Login Button (only on mobile)
                      // Show button if: not web, not checking, and biometric is available
                      if (!kIsWeb && !_checkingBiometric && _biometricAvailable)
                        _buildBiometricLoginSection(context, isMobile),

                      // Login Button
                      SizedBox(
                          height: isMobile ? AppSpacing.lg : AppSpacing.xl),
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
