import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;
  final String loadingText;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    required this.loadingText,
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
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
          foregroundColor: textColor ?? AppColors.accentWhite,
          elevation: isLoading ? 0 : 2,
          shadowColor: AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? AppColors.accentWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor ?? AppColors.accentWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
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