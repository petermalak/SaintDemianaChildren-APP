import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/view/widget/add_class_dialog.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/di/service_locator.dart';
import '../../../../../authentication/model/user_model.dart';
import '../../../../../scoring/view/screen/scoring_config_screen.dart';
import '../../../../../scoring/repository/i_scoring_repository.dart';
import '../../../../../scoring/viewmodel/config_cubit/config_cubit.dart';
import '../../../../../scoring/viewmodel/score_definition_cubit/score_definition_cubit.dart';
import '../../model/class_membership_model.dart';
import '../../model/class_model.dart';
import '../../repository/i_class_repository.dart';
import '../../viewmodel/get_classes/get_classes_cubit.dart';

class ClassCard extends StatefulWidget {
  const ClassCard(
      {super.key, required this.classItem, required this.cardAnimation});
  final ClassModel classItem;
  final Animation<double> cardAnimation;
  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    return AnimatedBuilder(
      animation: widget.cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.cardAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.04),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: AppColors.primaryMaroon,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.classItem.name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.classItem.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.classItem.description!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleClassAction(
                            value, widget.classItem, context),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    color: AppColors.primaryMaroon),
                                SizedBox(width: 12),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'members',
                            child: Row(
                              children: [
                                Icon(Icons.people,
                                    color: AppColors.primaryMaroon),
                                SizedBox(width: 12),
                                Text('الأعضاء'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'scoring',
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events,
                                    color: AppColors.accentGold),
                                SizedBox(width: 12),
                                Text('نظام التايو'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('حذف'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  isSmallScreen
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatChip(
                                    icon: Icons.people,
                                    label: 'الأعضاء',
                                    value: '${widget.classItem.memberCount}',
                                    color: AppColors.primaryMaroon,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: _buildStatChip(
                                    icon: Icons.person,
                                    label: 'الخدام',
                                    value: '${widget.classItem.khademCount}',
                                    color: AppColors.accentGold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatChip(
                                    icon: Icons.child_care,
                                    label: 'المخدومين',
                                    value: '${widget.classItem.makhdoumCount}',
                                    color: AppColors.primaryBrown,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(child: Container()), // Empty space
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.people,
                              label: 'الأعضاء',
                              value: '${widget.classItem.memberCount}',
                              color: AppColors.primaryMaroon,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            _buildStatChip(
                              icon: Icons.person,
                              label: 'الخدام',
                              value: '${widget.classItem.khademCount}',
                              color: AppColors.accentGold,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            _buildStatChip(
                              icon: Icons.child_care,
                              label: 'المخدومين',
                              value: '${widget.classItem.makhdoumCount}',
                              color: AppColors.primaryBrown,
                            ),
                          ],
                        ),
                  if (widget.classItem.location != null) ...[
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            widget.classItem.location!,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.classItem.schedule != null) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            widget.classItem.scheduleText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleClassAction(
      String action, ClassModel classItem, BuildContext context) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => AddClassDialog(
            classModel: classItem,
            onSuccess: () {
              setState(() {});
            },
          ),
        );
        break;
      case 'members':
        _showClassMembersDialog(classItem, context);
        break;
      case 'scoring':
        _navigateToScoringConfig(classItem, context);
        break;
      case 'delete':
        _showDeleteClassDialog(classItem, context);
        break;
    }
  }

  void _navigateToScoringConfig(ClassModel classItem, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ConfigCubit(sl<IScoringRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  ScoreDefinitionCubit(sl<IScoringRepository>()),
            ),
          ],
          child: ScoringConfigScreen(
            classId: classItem.id,
            className: classItem.name,
          ),
        ),
      ),
    );
  }

  void _showClassMembersDialog(ClassModel classItem, BuildContext context) {
    final memberships = classItem.memberships ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أعضاء ${classItem.name}'),
        content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: (memberships.isEmpty)
                ? const Center(
                    child: Text('لا يوجد أعضاء في هذا الفصل'),
                  )
                : Builder(builder: (context) {
                    return ListView.builder(
                      itemCount: memberships.length,
                      itemBuilder: (context, index) {
                        final membership = memberships[index];
                        final user = membership.user;
                        if (user == null) return const SizedBox.shrink();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role!)
                                .withValues(alpha: 0.1),
                            child: Icon(
                              _getRoleIcon(user.role!),
                              color: _getRoleColor(user.role!),
                            ),
                          ),
                          title: Text(user.name!),
                          subtitle: Text(user.email!),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleMembershipAction(
                                value, membership, classItem, context),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove_circle,
                                        color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('إزالة من الفصل'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  })),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showDeleteClassDialog(ClassModel classItem, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفصل'),
        content: Text('هل أنت متأكد من حذف "${classItem.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              sl<IClassRepository>().deleteClass(classItem.id);
              context.read<GetClassesCubit>().refreshClasses();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الفصل "${classItem.name}"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.accentWhite,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _handleMembershipAction(String action, ClassMembershipModel membership,
      ClassModel classItem, BuildContext context) {
    switch (action) {
      case 'remove':
        _showRemoveMemberDialog(membership, classItem, context);
        break;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return AppColors.accentGold;
      case UserRole.makhdoum:
        return AppColors.primaryBrown;
      case UserRole.superAdmin:
        return AppColors.primaryBlue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return Icons.person;
      case UserRole.makhdoum:
        return Icons.child_care;
      case UserRole.superAdmin:
        return Icons.supervisor_account;
    }
  }

  void _showRemoveMemberDialog(ClassMembershipModel membership,
      ClassModel classItem, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة عضو من الفصل'),
        content: Text(
            'هل أنت متأكد من إزالة ${membership.user?.name ?? 'هذا العضو'} من "${classItem.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              sl<IClassRepository>()
                  .removeUserFromClass(classItem.id, membership.userId);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'تم إزالة ${membership.user?.name ?? 'العضو'} من "${classItem.name}"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.accentWhite,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }
}
