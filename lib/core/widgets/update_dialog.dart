import 'package:flutter/material.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/constants/spacing.dart';
import 'package:saint_demiana_children/core/services/interface/i_update_service.dart';

/// Dialog for showing app update information
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdate;
  final VoidCallback? onCancel;
  final bool isForceUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onUpdate,
    this.onCancel,
    this.isForceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForceUpdate, // Prevent dismiss on force update
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: isForceUpdate ? AppColors.error : AppColors.primaryMaroon,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                isForceUpdate ? 'تحديث إلزامي' : 'تحديث متاح',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isForceUpdate
                          ? AppColors.error
                          : AppColors.primaryMaroon,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isForceUpdate
                  ? 'يجب تحديث التطبيق للاستمرار في الاستخدام.'
                  : 'يتوفر تحديث جديد للتطبيق. ننصح بالتحديث للحصول على أفضل تجربة.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (updateInfo.updateVersion != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'الإصدار: ${updateInfo.updateVersion}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (updateInfo.releaseNotes != null &&
                updateInfo.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'ملاحظات الإصدار:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                updateInfo.releaseNotes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          if (!isForceUpdate && onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: Text(
                'لاحقاً',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ElevatedButton(
            onPressed: onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: isForceUpdate
                  ? AppColors.error
                  : AppColors.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }
}

/// Loading dialog shown during update download
class UpdateDownloadDialog extends StatelessWidget {
  final String? message;

  const UpdateDownloadDialog({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMaroon),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message ?? 'جاري تحميل التحديث...',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

