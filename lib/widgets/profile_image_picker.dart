import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants/app_colors.dart';
import '../core/constants/spacing.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imagePath;
  final Function(String?) onImageChanged;
  final bool isEditable;

  const ProfileImagePicker({
    super.key,
    this.imagePath,
    required this.onImageChanged,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: isEditable ? () => _showImagePicker(context) : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryMaroon,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMaroon.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: imagePath != null && imagePath!.isNotEmpty
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isEditable)
            TextButton.icon(
              onPressed: () => _showImagePicker(context),
              icon: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryMaroon,
                size: 18,
              ),
              label: const Text(
                'تغيير الصورة',
                style: TextStyle(
                  color: AppColors.primaryMaroon,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (imagePath != null && imagePath!.isNotEmpty && isEditable)
            TextButton.icon(
              onPressed: () => onImageChanged(null),
              icon: const Icon(
                Icons.delete,
                color: AppColors.error,
                size: 18,
              ),
              label: const Text(
                'حذف الصورة',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.accentWhite,
        size: 60,
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'اختر صورة الملف الشخصي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  context,
                  Icons.camera_alt,
                  'الكاميرا',
                  () => _pickImage(context, ImageSource.camera),
                ),
                _buildPickerOption(
                  context,
                  Icons.photo_library,
                  'المعرض',
                  () => _pickImage(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primaryMaroon.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryMaroon,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryMaroon,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      Navigator.pop(context); // Close bottom sheet
      
      if (image != null) {
        onImageChanged(image.path);
      }
    } catch (e) {
      Navigator.pop(context); // Close bottom sheet
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في اختيار الصورة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
