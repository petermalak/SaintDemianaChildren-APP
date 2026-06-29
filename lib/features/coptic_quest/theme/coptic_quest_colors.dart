import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CopticQuestColors {
  // Sky adventure palette — bright and welcoming for children
  static const Color skyTop = Color(0xFF4A8FE7);
  static const Color skyBottom = Color(0xFFB8DCFF);
  static const Color cloudWhite = Color(0xFFFFFDF8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E6B);
  static const Color textMuted = Color(0xFF6B7B9A);
  static const Color funOrange = Color(0xFFFF9F43);
  static const Color funGreen = Color(0xFF58CC02);
  static const Color funPink = Color(0xFFFF6B9D);
  static const Color funPurple = Color(0xFF9B59B6);

  // Legacy aliases used across widgets
  static const Color deepMocha = skyTop;
  static const Color deepMocha2 = cardSurface;
  static const Color dimGrey = textMuted;
  static const Color paleSlate = textDark;
  static const Color black = Color(0xFF1A1A2E);
  static const Color accentGold = AppColors.accentGold;

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, skyBottom],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), accentGold],
  );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static ThemeData theme(BuildContext context) {
    final parent = Theme.of(context);
    return parent.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: skyTop,
      colorScheme: parent.colorScheme.copyWith(
        primary: accentGold,
        secondary: funOrange,
        surface: cardSurface,
        onPrimary: black,
        onSurface: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: funOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 4,
          shadowColor: funOrange.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: parent.textTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
    );
  }
}
