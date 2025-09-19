import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/spacing.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  
  late AnimationController _formAnimationController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _formAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutBack,
    );
    
    // Start form animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 500,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                    _buildLogoSection(context),
                    SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                    _buildFormSection(context),
                    SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final logoSize = isMobile ? 80.0 : (MediaQuery.of(context).size.width < 1024 ? 100.0 : 120.0);
    
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _formAnimation.value,
          child: Opacity(
            opacity: _formAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMaroon.withValues(alpha: 0.4.clamp(0.0, 1.0)),
                    blurRadius: AppSpacing.shadowBlurLg,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                    blurRadius: AppSpacing.shadowBlurXl,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
              child: Column(
                children: [
                  // Church Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMaroon.withValues(alpha: 0.4.clamp(0.0, 1.0)),
                          blurRadius: AppSpacing.shadowBlurLg,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.accentGold.withValues(alpha: 0.2.clamp(0.0, 1.0)),
                          blurRadius: AppSpacing.shadowBlurXl,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryCream,
                              Color(0xFFF0E6D2),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to gradient circle if logo not found
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: Icon(
                                  Icons.church,
                                  size: logoSize * 0.5,
                                  color: AppColors.accentWhite,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                  Text(
                    'كنيسة القديسة دميانة',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? AppSpacing.lg + 4 : AppSpacing.xl,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Saint Demiana Coptic Orthodox Church',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? AppSpacing.md - 2 : AppSpacing.md,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Diocese of Los Angeles and Hawaii',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: AppSpacing.sm + 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _formAnimation.value)),
          child: Opacity(
            opacity: _formAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                border: Border.all(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMaroon.withValues(alpha: 0.15.clamp(0.0, 1.0)),
                    blurRadius: AppSpacing.shadowBlurLg,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                    blurRadius: AppSpacing.shadowBlurXl,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تسجيل الدخول',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? AppSpacing.lg + 2 : AppSpacing.xl,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Login to your account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: AppSpacing.md,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                      
                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'البريد الإلكتروني',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                      
                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'كلمة المرور',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
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
                    const SizedBox(height: 24),
                      
                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return LoadingButton(
                          onPressed: _handleLogin,
                          isLoading: authProvider.isLoading,
                          text: 'تسجيل الدخول',
                          loadingText: 'جاري تسجيل الدخول...',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Clear any previous errors
    authProvider.clearError();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Get the current user's role and navigate accordingly
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        switch (currentUser.role) {
          case UserRole.khadem:
            context.go('/khadem');
            break;
          case UserRole.makhdoum:
            context.go('/makhdoum');
            break;
        }
      }
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}