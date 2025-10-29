/// Spacing constants for consistent UI layout
class AppSpacing {
  // Base spacing unit (8px)
  static const double baseUnit = 8.0;

  // Spacing values
  static const double xs = baseUnit * 0.5; // 4px
  static const double sm = baseUnit; // 8px
  static const double md = baseUnit * 2; // 16px
  static const double lg = baseUnit * 3; // 24px
  static const double xl = baseUnit * 4; // 32px
  static const double xxl = baseUnit * 6; // 48px
  static const double xxxl = baseUnit * 8; // 64px

  // Screen-specific spacing
  static const double screenPadding = md;
  static const double cardPadding = md;
  static const double sectionSpacing = xl;
  static const double componentSpacing = lg;

  // Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 20.0;
  static const double radiusRound = 50.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;

  // Button heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  // Input field heights
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;

  // Card dimensions
  static const double cardMinHeight = 120.0;
  static const double cardMaxWidth = 400.0;
  static const double cardElevation = 2.0;

  // App bar height
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  // Bottom navigation height
  static const double bottomNavHeight = 60.0;
  static const double bottomNavHeightLarge = 80.0;

  // Drawer width
  static const double drawerWidth = 280.0;
  static const double drawerWidthLarge = 320.0;

  // List item heights
  static const double listItemHeightSm = 48.0;
  static const double listItemHeightMd = 56.0;
  static const double listItemHeightLg = 64.0;

  // Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarXxl = 80.0;

  // Divider thickness
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;

  // Shadow blur radius
  static const double shadowBlurSm = 2.0;
  static const double shadowBlurMd = 4.0;
  static const double shadowBlurLg = 8.0;
  static const double shadowBlurXl = 16.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Z-index values
  static const double zIndexDropdown = 1000.0;
  static const double zIndexModal = 1050.0;
  static const double zIndexToast = 1100.0;
  static const double zIndexTooltip = 1150.0;
}
