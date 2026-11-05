import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/role_helper.dart';
import '../../model/user_model.dart';

/// One row per active membership: the role in that class, not a generic interface.
class RoleSelectionDialog extends StatelessWidget {
  final List<RoleClassSelection> contexts;
  final void Function(RoleClassSelection selection) onContextSelected;

  const RoleSelectionDialog({
    super.key,
    required this.contexts,
    required this.onContextSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر الفصل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'كل صف هو دورك في فصل واحد',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contexts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final selection = contexts[index];
                    return Material(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.primaryMaroon.withValues(alpha: 0.25),
                          ),
                        ),
                        leading: Icon(
                          _iconFor(selection.role),
                          color: AppColors.primaryMaroon,
                        ),
                        title: Text(selection.displayName),
                        onTap: () {
                          Navigator.of(context).pop();
                          onContextSelected(selection);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return Icons.groups_outlined;
      case UserRole.makhdoum:
        return Icons.person_outline;
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
