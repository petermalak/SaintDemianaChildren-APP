import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/spacing.dart';

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditable;
  final bool isRequired;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.isEditable = true,
    this.isRequired = false,
    this.controller,
    this.validator,
    this.onTap,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryMaroon,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (isEditable)
            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: value.isEmpty ? 'أدخل $label' : null,
                suffixIcon: suffixIcon,
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
                      color: AppColors.primaryMaroon, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isEditable
                        ? AppColors.borderLight
                        : AppColors.borderMedium,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'غير محدد' : value,
                        style: TextStyle(
                          fontSize: 16,
                          color: value.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontStyle: value.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    if (isEditable)
                      Icon(
                        Icons.edit,
                        color: AppColors.primaryMaroon.withValues(alpha: 0.7),
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
