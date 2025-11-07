import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ResponsiveDialogSizing {
  const ResponsiveDialogSizing({
    required this.width,
    required this.minHeight,
    required this.maxHeight,
  });

  final double width;
  final double minHeight;
  final double maxHeight;

  BoxConstraints toConstraints({bool lockWidth = false}) {
    return BoxConstraints(
      minWidth: lockWidth ? width : 0,
      maxWidth: lockWidth ? width : double.infinity,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }
}

class ResponsiveDialogUtils {
  const ResponsiveDialogUtils._();

  static ResponsiveDialogSizing buildSizing(
    Size screenSize, {
    double minWidth = 420,
    double maxWidth = 1200,
    double maxHeightFactor = 0.92,
    double compactHeightFactor = 0.62,
    double regularHeightFactor = 0.74,
  }) {
    final width = _resolveWidth(
      screenSize.width,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
    final maxHeight = screenSize.height * maxHeightFactor;
    final minHeightBase = screenSize.height *
        (screenSize.height < 780 ? compactHeightFactor : regularHeightFactor);
    final minHeight = math.min(minHeightBase, maxHeight);

    return ResponsiveDialogSizing(
      width: width,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  static double _resolveWidth(
    double screenWidth, {
    required double minWidth,
    required double maxWidth,
  }) {
    double width;
    if (screenWidth <= 480) {
      width = screenWidth * 0.985;
    } else if (screenWidth <= 768) {
      width = screenWidth * 0.9;
    } else if (screenWidth <= 1024) {
      width = screenWidth * 0.82;
    } else if (screenWidth <= 1366) {
      width = screenWidth * 0.74;
    } else if (screenWidth <= 1600) {
      width = screenWidth * 0.68;
    } else if (screenWidth <= 1920) {
      width = screenWidth * 0.62;
    } else {
      width = screenWidth * 0.56;
    }

    return width.clamp(minWidth, maxWidth).toDouble();
  }
}

class DialogTypographyScale {
  const DialogTypographyScale({
    required this.headline,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.button,
  });

  final double headline;
  final double title;
  final double subtitle;
  final double body;
  final double label;
  final double button;
}

class ResponsiveDialogTypography {
  const ResponsiveDialogTypography._();

  static DialogTypographyScale resolve(Size screenSize) {
    final factor = _scaleFactor(screenSize.width);

    return DialogTypographyScale(
      headline: 22 * factor,
      title: 19 * factor,
      subtitle: 17 * factor,
      body: 15.5 * factor,
      label: 14 * factor,
      button: 16.5 * factor,
    );
  }

  static double _scaleFactor(double width) {
    if (width <= 480) return 0.95;
    if (width <= 768) return 1.0;
    if (width <= 1024) return 1.05;
    if (width <= 1366) return 1.12;
    if (width <= 1600) return 1.18;
    if (width <= 1920) return 1.24;
    return 1.32;
  }

  static TextStyle merge(
    TextStyle? base,
    double size, {
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: size,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
}

