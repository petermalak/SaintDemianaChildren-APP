import 'package:flutter/material.dart';
import '../../features/authentication/model/user_model.dart';
import '../utils/role_helper.dart';

/// Widget to select role and class for users with mixed roles
class RoleClassSelector extends StatelessWidget {
  final UserModel user;
  final RoleClassSelection? selected;
  final Function(RoleClassSelection) onSelectionChanged;
  final bool showLabel;

  const RoleClassSelector({
    super.key,
    required this.user,
    this.selected,
    required this.onSelectionChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasMixedRoles = RoleHelper.hasMixedRoles(user);
    
    // If user doesn't have mixed roles, don't show selector
    if (!hasMixedRoles) {
      return const SizedBox.shrink();
    }

    final khademClasses = RoleHelper.getKhademClasses(user);
    final makhdoumClasses = RoleHelper.getMakhdoumClasses(user);
    final canBeKhadem = RoleHelper.canAccessKhademFeatures(user);
    final canBeMakhdoum = RoleHelper.canAccessMakhdoumFeatures(user);

    // Build list of available role/class combinations
    final List<RoleClassSelection> options = [];
    
    if (canBeKhadem) {
      if (khademClasses.isEmpty) {
        // User is khadem but no specific classes (super admin case)
        options.add(const RoleClassSelection(
          role: UserRole.khadem,
        ));
      } else {
        for (final classInfo in khademClasses) {
          options.add(RoleClassSelection(
            role: UserRole.khadem,
            classId: classInfo.classId,
            className: classInfo.className,
          ));
        }
      }
    }
    
    if (canBeMakhdoum) {
      for (final classInfo in makhdoumClasses) {
        options.add(RoleClassSelection(
          role: UserRole.makhdoum,
          classId: classInfo.classId,
          className: classInfo.className,
        ));
      }
    }

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one option, don't show selector but set it
    if (options.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (selected == null || 
            selected!.role != options.first.role ||
            selected!.classId != options.first.classId) {
          onSelectionChanged(options.first);
        }
      });
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اختر الدور والصف',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected != null &&
                  selected!.role == option.role &&
                  selected!.classId == option.classId;
              
              return GestureDetector(
                onTap: () => onSelectionChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option.role == UserRole.khadem
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

