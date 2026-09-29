import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/communication_service.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../scoring/view/widget/manage_points_dialog.dart';
import '../../../../scoring/view/widget/score_badge_widget.dart';
import '../../../../scoring/viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../../../scoring/repository/i_scoring_repository.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import 'add_user_dialog.dart';

class MemberCard extends StatefulWidget {
  const MemberCard({
    super.key,
    required this.cardAnimation,
    required this.user,
    required this.selectedList,
    this.onSelectionChanged,
    required this.onUpdate,
    this.isCompact = false,
    this.isListView = false,
  });

  final Animation<double> cardAnimation;
  final UserModel user;
  final List<UserModel> selectedList;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback onUpdate;
  final bool isCompact;
  final bool isListView;

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  bool isSelected = false;
  int _refreshKey = 0;

  void _showContactDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final communicationService = CommunicationService();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.only(right: 18, left: 18, top: 12, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.name!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.accentDark),
                title: const Text('Edit profile'),
                onTap: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AddUserDialog(
                      onSuccess: () {
                        widget.onUpdate();
                      },
                      user: widget.user,
                    ),
                  );
                },
              ),
              // Show manage points option for makhdoum only
              _buildManagePointsTile(context),
              if (widget.user.classSummaries.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildClassMembershipSection(),
              ],
              ListTile(
                leading:
                    const Icon(Icons.phone, color: AppColors.primaryMaroon),
                title: const Text('Call the number'),
                onTap: () async {
                  final response = await communicationService.makePhoneCall(
                    widget.user.phoneNumber!,
                  );
                  response.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'جاري الاتصال بـ ${widget.user.phoneNumber}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                  leading: const Icon(Icons.message, color: Colors.green),
                  title: const Text('Send WhatsApp message'),
                  onTap: () async {
                    (await communicationService.openWhatsAppChat(
                      widget.user.phoneNumber!,
                    ))
                        .fold((failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }, (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'جاري فتح واتساب للتواصل مع ${widget.user.phoneNumber!}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
  }

  Widget _buildManagePointsTile(BuildContext context) {
    if (widget.user.role != UserRole.makhdoum) {
      return const SizedBox.shrink();
    }

    final currentUser = sl<IProfileRepository>().user;
    final currentUserId = currentUser?.id;
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;

    final currentUserClasses = currentUser?.classes ?? const <UserClassInfo>[];
    final currentKhademClassIds = currentUserClasses
        .where((info) =>
            info.membershipRole == 'khadem' && (info.isActive ?? true))
        .map((info) => info.classId)
        .toSet();

    final permittedSummaries = widget.user.classSummaries.where((summary) {
      final isMakhdoumMembership =
          summary.membershipRole == 'makhdoum' || summary.membershipRole == null;
      if (!isMakhdoumMembership) {
        return false;
      }

      if (isSuperAdmin == true) {
        return true;
      }

      if (currentUserId == null) {
        return false;
      }

      final explicitlyAssigned = summary.assignedKhadems
          .any((khadem) => khadem.id == currentUserId);

      final sharesClass =
          currentKhademClassIds.contains(summary.classId);

      return explicitlyAssigned || sharesClass;
    }).toList();

    if (permittedSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    final uniqueSummaries = {
      for (final summary in permittedSummaries) summary.classId: summary
    }.values.toList();

    return ListTile(
      leading: const Icon(Icons.emoji_events, color: AppColors.accentGold),
      title: const Text('إدارة النقاط'),
      subtitle: uniqueSummaries.length == 1
          ? Text(uniqueSummaries.first.className ?? 'الفصل الحالي')
          : const Text('اختر الفصل لإدارة النقاط'),
      onTap: () => _openManagePointsSelector(
        uniqueSummaries,
        isSuperAdmin == true ? widget.user.primaryClassId : null,
      ),
    );
  }

  void _openManagePointsSelector(
    List<UserClassSummary> summaries,
    String? fallbackClassId,
  ) {
    final availableSummaries = summaries.isNotEmpty
        ? summaries
        : (fallbackClassId != null
            ? [
                _buildFallbackSummary(fallbackClassId),
              ]
            : <UserClassSummary>[]);

    if (availableSummaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد فصل مرتبط لإدارة النقاط'),
        ),
      );
      return;
    }

    if (availableSummaries.length == 1) {
      Navigator.pop(context);
      _openManagePointsForClass(availableSummaries.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر الفصل لإدارة النقاط',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ...availableSummaries.map(
              (summary) => ListTile(
                leading: const Icon(Icons.class_rounded),
                title: Text(summary.className ?? 'فصل بدون اسم'),
                subtitle: Text(summary.khademNames),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pop(context);
                  _openManagePointsForClass(summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openManagePointsForClass(UserClassSummary summary) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) => ScoringCubit(sl<IScoringRepository>()),
        child: ManagePointsDialog(
          userId: widget.user.id!,
          userName: widget.user.name ?? '',
          classId: summary.classId,
          className: summary.className,
        ),
      ),
    ).then((_) {
      setState(() {
        _refreshKey++;
      });
      widget.onUpdate();
    });
  }

  UserClassSummary _buildFallbackSummary(String classId) {
    UserClassInfo? membership;
    try {
      membership = widget.user.classes.firstWhere(
        (info) => info.classId == classId,
      );
    } catch (_) {
      membership = null;
    }

    return UserClassSummary(
      classId: classId,
      className: membership?.className,
      membershipRole: membership?.membershipRole ?? 'makhdoum',
    );
  }

  Widget _buildClassMembershipSection() {
    final summaries = widget.user.classSummaries;
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'الفصول المرتبطة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...summaries.map(
          (summary) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.class_outlined,
              color: AppColors.primaryMaroon.withValues(alpha: 0.8),
            ),
            title: Text(summary.className ?? 'فصل بدون اسم'),
            subtitle: Text(
              summary.membershipRole == 'khadem'
                  ? 'الدور: ${_localizeMembershipRole(summary.membershipRole)}'
                  : summary.khademNames,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildClassAssignmentsSection({required bool compact}) {
    final summaries = widget.user.classSummaries;
    if (summaries.isEmpty) {
      return null;
    }

    if (compact) {
      final names = summaries
          .map((summary) => summary.className?.trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .join(' • ');
      if (names.isEmpty) return null;
      return Text(
        names,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: summaries
          .map((summary) => _buildClassChip(summary, compact: compact))
          .toList(),
    );
  }

  Widget _buildClassChip(UserClassSummary summary,
      {required bool compact}) {
    final description = summary.membershipRole == 'makhdoum'
        ? summary.khademNames
        : 'الدور: ${_localizeMembershipRole(summary.membershipRole)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withValues(alpha: 0.05.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.2.clamp(0.0, 1.0)),
        ),
      ),
      constraints: const BoxConstraints(minWidth: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary.className ?? 'فصل بدون اسم',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: compact ? 8 : 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _localizeMembershipRole(String? role) {
    switch (role) {
      case 'khadem':
        return 'خادم';
      case 'makhdoum':
        return 'مخدوم';
      default:
        return 'عضو';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - widget.cardAnimation.value)),
          child: Opacity(
            opacity: widget.cardAnimation.value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () {
                if (widget.selectedList.isEmpty) {
                  _showContactDrawer(context);
                } else {
                  isSelected = !isSelected;
                  if (isSelected) {
                    widget.selectedList.add(widget.user);
                  } else {
                    widget.selectedList
                        .removeWhere((element) => element.id == widget.user.id);
                  }
                  widget.onSelectionChanged?.call(isSelected);
                  setState(() {});
                }
              },
              onLongPress: () {
                if (widget.selectedList.isEmpty) {
                  isSelected = !isSelected;
                  if (isSelected) {
                    widget.selectedList.add(widget.user);
                  } else {
                    widget.selectedList
                        .removeWhere((element) => element.id == widget.user.id);
                  }
                  widget.onSelectionChanged?.call(isSelected);
                  setState(() {});
                }
              },
              child: widget.isListView
                  ? _buildListViewCard()
                  : _buildGridViewCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridViewCard() {
    final badgeClassId = widget.user.primaryClassId;
    final classAssignmentsSection =
        _buildClassAssignmentsSection(compact: true);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0))
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: widget.isCompact ? 22 : 28,
                    backgroundColor: _getRoleColor(widget.user.role!),
                    child: Text(
                      widget.user.name!.isNotEmpty
                          ? widget.user.name![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.accentWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.isCompact ? 15 : 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.user.name!,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isCompact
                        ? widget.user.roleDisplayName
                        : widget.user.role!.name,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 10 : 11,
                      color: _getRoleColor(widget.user.role!),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.user.role == UserRole.makhdoum &&
                      badgeClassId != null) ...[
                    const SizedBox(height: 6),
                    ScoreBadgeWidget(
                      key: ValueKey('score_${widget.user.id}_$_refreshKey'),
                      userId: widget.user.id!,
                      classId: badgeClassId,
                      compact: true,
                    ),
                  ],
                  if (classAssignmentsSection != null) ...[
                    const SizedBox(height: 4),
                    classAssignmentsSection,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListViewCard() {
    final badgeClassId = widget.user.primaryClassId;
    final classAssignmentsSection =
        _buildClassAssignmentsSection(compact: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryMaroon.withValues(alpha: 0.3.clamp(0.0, 1.0))
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: _getRoleColor(widget.user.role!),
            child: Text(
              widget.user.name!.isNotEmpty
                  ? widget.user.name![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.accentWhite,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 12,
                      color: _getRoleColor(widget.user.role!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.user.roleDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRoleColor(widget.user.role!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (widget.user.phoneNumber != null &&
                    widget.user.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 12,
                        color: AppColors.primaryMaroon
                            .withValues(alpha: 0.7.clamp(0.0, 1.0)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.user.phoneNumber!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryMaroon
                                .withValues(alpha: 0.7.clamp(0.0, 1.0)),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
                // Show score badge for makhdoum only
                if (widget.user.role == UserRole.makhdoum &&
                    badgeClassId != null) ...[
                  const SizedBox(height: 6),
                  ScoreBadgeWidget(
                    key: ValueKey('score_${widget.user.id}_$_refreshKey'),
                    userId: widget.user.id!,
                    classId: badgeClassId,
                    compact: true,
                  ),
                ],
                if (classAssignmentsSection != null) ...[
                  const SizedBox(height: 8),
                  classAssignmentsSection,
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color:
                AppColors.textSecondary.withValues(alpha: 0.5.clamp(0.0, 1.0)),
          ),
        ],
      ),
    );
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
}
