import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/role_helper.dart';
import '../../model/user_model.dart';

/// Dialog to select role for users with multiple roles after login
class RoleSelectionDialog extends StatelessWidget {
  final UserModel user;
  final Function(UserRole) onRoleSelected;

  const RoleSelectionDialog({
    super.key,
    required this.user,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final canBeKhadem = RoleHelper.canAccessKhademFeatures(user);
    final canBeMakhdoum = RoleHelper.canAccessMakhdoumFeatures(user);
    final khademClasses = RoleHelper.getKhademClasses(user);
    final makhdoumClasses = RoleHelper.getMakhdoumClasses(user);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz,
                    color: AppColors.accentWhite,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'اختر نوع الواجهة',
                      style: TextStyle(
                        color: AppColors.accentWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Description
            const Text(
              'لديك أدوار متعددة. اختر الواجهة التي تريد استخدامها:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Role options
            if (canBeKhadem) ...[
              _buildRoleOption(
                context: context,
                icon: Icons.admin_panel_settings,
                title: 'واجهة الخادم',
                subtitle: khademClasses.isNotEmpty
                    ? '${khademClasses.length} فصل'
                    : 'جميع الفصول',
                color: AppColors.primaryMaroon,
                onTap: () {
                  Navigator.of(context).pop();
                  onRoleSelected(UserRole.khadem);
                },
              ),
              const SizedBox(height: 12),
            ],
            
            if (canBeMakhdoum) ...[
              _buildRoleOption(
                context: context,
                icon: Icons.person,
                title: 'واجهة المخدوم',
                subtitle: makhdoumClasses.isNotEmpty
                    ? '${makhdoumClasses.length} فصل'
                    : 'فصلي',
                color: AppColors.primaryBlue,
                onTap: () {
                  Navigator.of(context).pop();
                  onRoleSelected(UserRole.makhdoum);
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك التبديل بين الواجهات من القائمة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

