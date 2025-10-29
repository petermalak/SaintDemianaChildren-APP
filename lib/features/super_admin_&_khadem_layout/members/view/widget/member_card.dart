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
              if (widget.user.role == UserRole.makhdoum &&
                  widget.user.classId != null)
                ListTile(
                  leading: const Icon(Icons.emoji_events,
                      color: AppColors.accentGold),
                  title: const Text('إدارة النقاط'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider(
                        create: (context) =>
                            ScoringCubit(sl<IScoringRepository>()),
                        child: ManagePointsDialog(
                          userId: widget.user.id!,
                          userName: widget.user.name!,
                          classId: widget.user.classId!,
                        ),
                      ),
                    ).then((_) {
                      // Refresh after dialog closes
                      setState(() {
                        _refreshKey++; // Force ScoreBadgeWidget to reload
                      });
                      widget.onUpdate();
                    });
                  },
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: widget.isCompact ? 25 : 30,
            backgroundColor: _getRoleColor(widget.user.role!),
            child: Text(
              widget.user.name!.isNotEmpty
                  ? widget.user.name![0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.accentWhite,
                fontWeight: FontWeight.bold,
                fontSize: widget.isCompact ? 16 : 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
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
          ),
          if (widget.isCompact) ...[
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                widget.user.roleDisplayName,
                style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(widget.user.role!),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                widget.user.role!.name,
                style: TextStyle(
                  fontSize: 11,
                  color: _getRoleColor(widget.user.role!),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          // Show score badge for makhdoum only
          if (widget.user.role == UserRole.makhdoum &&
              widget.user.classId != null) ...[
            const SizedBox(height: 6),
            ScoreBadgeWidget(
              key: ValueKey('score_${widget.user.id}_$_refreshKey'),
              userId: widget.user.id!,
              classId: widget.user.classId!,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListViewCard() {
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
                    widget.user.classId != null) ...[
                  const SizedBox(height: 6),
                  ScoreBadgeWidget(
                    key: ValueKey('score_${widget.user.id}_$_refreshKey'),
                    userId: widget.user.id!,
                    classId: widget.user.classId!,
                    compact: true,
                  ),
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
