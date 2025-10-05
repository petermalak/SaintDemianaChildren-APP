import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
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
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(
          fontSize: AppSpacing.xxxl, // 64px
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: AppSpacing.xxl, // 48px
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: AppSpacing.xl, // 32px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: AppSpacing.lg + 6, // 30px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: AppSpacing.lg + 2, // 26px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: AppSpacing.lg, // 24px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: AppSpacing.md, // 16px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: AppSpacing.sm + 4, // 12px
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: AppSpacing.md, // 16px
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: AppSpacing.sm + 4, // 12px
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: AppSpacing.md - 2, // 14px
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: AppSpacing.sm + 2, // 10px
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.cairo(
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
        titleTextStyle: GoogleFonts.cairo(
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
          textStyle: GoogleFonts.cairo(
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
          textStyle: GoogleFonts.cairo(
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
          textStyle: GoogleFonts.cairo(
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
        labelStyle: GoogleFonts.cairo(
          color: AppColors.textSecondary,
          fontSize: AppSpacing.md - 2, // 14px
        ),
        hintStyle: GoogleFonts.cairo(
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
      ),
    );
  }
}
