import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from the church logo
  static const Color primaryMaroon = Color(0xFF6B1A2B); // Darker reddish-brown from outer ring
  static const Color primaryCream = Color(0xFFF7F3E9); // Warm yellow-cream background
  static const Color primaryBlue = Color(0xFF2E5B8A); // Light blue for surrounding figures (darker)
  static const Color primaryBrown = Color(0xFF8B4513); // Brown for Saint Demiana's robe (replacing purple)
  
  // Accent colors
  static const Color accentGold = Color(0xFFD4AF37); // Rich gold for halos and crosses
  static const Color accentGreen = Color(0xFF2D5A27); // Darker green for palm fronds
  static const Color accentWhite = Color(0xFFFFFFFF); // White text
  static const Color accentDark = Color(0xFF2C1810); // Dark brown for outlines
  
  // Status colors using logo colors
  static const Color success = accentGreen; // Use green from logo
  static const Color warning = accentGold; // Use gold from logo
  static const Color error = primaryMaroon; // Use maroon from logo
  static const Color info = primaryBlue; // Use blue from logo
  
  // Background colors using logo colors
  static const Color backgroundPrimary = primaryCream;
  static final Color backgroundSecondary = primaryCream.withValues(alpha: 0.8);
  static const Color backgroundCard = accentWhite;
  
  // Text colors using logo colors
  static const Color textPrimary = accentDark;
  static final Color textSecondary = primaryMaroon.withValues(alpha: 0.7);
  static const Color textLight = accentWhite;
  
  // Button colors
  static const Color buttonPrimary = primaryMaroon;
  static const Color buttonSecondary = primaryBrown;
  static const Color buttonAccent = accentGold;
  
  // Border colors using logo colors
  static final Color borderLight = primaryCream.withValues(alpha: 0.3);
  static final Color borderMedium = primaryMaroon.withValues(alpha: 0.5);
  static const Color borderDark = accentDark;
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMaroon, primaryBrown],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, Color(0xFFFFA500)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF7F3E9), // primaryCream
      Color(0xFFF0E6D2), // warmer cream
      Color(0xFFE8DCC6), // even warmer
    ],
  );
}