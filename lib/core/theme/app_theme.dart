import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/spacing.dart';

TextStyle cairo({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Cairo',
    fontFamilyFallback: const ['CairoArabic'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseText = ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['CairoArabic'],
    ).textTheme.apply(
          fontFamily: 'Cairo',
          fontFamilyFallback: const ['CairoArabic'],
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['CairoArabic'],
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryMaroon,
        primary: AppColors.primaryMaroon,
        secondary: AppColors.primaryBrown,
        tertiary: AppColors.accentGold,
        surface: AppColors.backgroundCard,
        // background: AppColors.backgroundPrimary, // Deprecated, using surface instead
        error: AppColors.error,
      ),

      // Text Theme with responsive typography
      textTheme: baseText.copyWith(
        displayLarge: cairo(
          fontSize: AppSpacing.xxxl, // 64px
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: cairo(
          fontSize: AppSpacing.xxl, // 48px
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displaySmall: cairo(
          fontSize: AppSpacing.xl, // 32px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineLarge: cairo(
          fontSize: AppSpacing.lg + 6, // 30px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineMedium: cairo(
          fontSize: AppSpacing.lg + 2, // 26px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineSmall: cairo(
          fontSize: AppSpacing.lg, // 24px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleLarge: cairo(
          fontSize: AppSpacing.md, // 16px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleMedium: cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleSmall: cairo(
          fontSize: AppSpacing.sm + 4, // 12px
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodyLarge: cairo(
          fontSize: AppSpacing.md, // 16px
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: cairo(
          fontSize: AppSpacing.sm + 4, // 12px
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        labelMedium: cairo(
          fontSize: AppSpacing.sm + 2, // 10px
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelSmall: cairo(
          fontSize: AppSpacing.sm, // 8px
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: AppSpacing.appBarHeight,
        titleTextStyle: cairo(
          fontSize: AppSpacing.lg - 2, // 22px
          fontWeight: FontWeight.w600,
          color: AppColors.accentWhite,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: AppSpacing.cardElevation,
        shadowColor:
            AppColors.primaryMaroon.withValues(alpha: 0.1.clamp(0.0, 1.0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.accentWhite,
          elevation: AppSpacing.shadowBlurSm,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: cairo(
            fontSize: AppSpacing.md,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
          side: const BorderSide(
              color: AppColors.buttonPrimary,
              width: AppSpacing.dividerThicknessBold),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: cairo(
            fontSize: AppSpacing.md,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          textStyle: cairo(
            fontSize: AppSpacing.md - 2, // 14px
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
              color: AppColors.buttonPrimary,
              width: AppSpacing.dividerThicknessBold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
              color: AppColors.error, width: AppSpacing.dividerThicknessBold),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        labelStyle: cairo(
          color: AppColors.textSecondary,
          fontSize: AppSpacing.md - 2, // 14px
        ),
        hintStyle: cairo(
          color: AppColors.textSecondary,
          fontSize: AppSpacing.md - 2, // 14px
        ),
      ),

      //circular progress indicator theme
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.buttonPrimary),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        selectedItemColor: AppColors.buttonPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: AppSpacing.shadowBlurMd,
        selectedLabelStyle: cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: cairo(fontSize: 11),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accentDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentTextStyle: cairo(
          color: AppColors.accentWhite,
          fontSize: 14,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
