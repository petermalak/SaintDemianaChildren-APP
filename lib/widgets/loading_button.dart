import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const SubmitButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
          foregroundColor: textColor ?? AppColors.accentWhite,
          elevation: 2,
          shadowColor:
              AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor ?? AppColors.accentWhite,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
