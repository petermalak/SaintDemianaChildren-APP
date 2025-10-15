import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/communication_service.dart';
import '../../../../authentication/model/user_model.dart';
import 'add_user_dialog.dart';

class MemberCard extends StatefulWidget {
  const MemberCard({super.key,
    required this.cardAnimation,
    required this.user,
    required this.selectedList,
    this.onSelectionChanged,required this.onUpdate});

  final Animation<double> cardAnimation;
  final UserModel user;
  final List<UserModel> selectedList;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback onUpdate;

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  bool isSelected = false;

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
                    builder: (dialogContext) =>
                        AddUserDialog(
                          onSuccess: () {
                            widget.onUpdate();
                          },
                          user: widget.user,
                        ),
                  );
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
                              'جاري فتح واتساب للتواصل مع ${widget.user
                                  .phoneNumber!}'),
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
              child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryMaroon
                        .withValues(alpha: 0.3.clamp(0.0, 1.0))
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.05.clamp(0.0, 1.0)),
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
                        radius: 30,
                        backgroundColor: _getRoleColor(widget.user.role!),
                        child: Text(
                          widget.user.name!.isNotEmpty
                              ? widget.user.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.accentWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          widget.user.name!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                  )),
            ),
          ),
        );
      },
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
