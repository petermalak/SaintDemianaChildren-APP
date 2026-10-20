import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../authentication/model/user_model.dart';

class ScannedMemberTile extends StatelessWidget {
  const ScannedMemberTile({
    super.key,
    required this.member,
    required this.onRemove,
    this.index,
  });

  final UserModel member;
  final VoidCallback onRemove;
  final int? index;

  String get _groupLabel {
    final meeting = member.popeAthnasiusMeetingData;
    if (meeting == null) return 'الفرقة الثانية';
    const groups = {1: 'الأسر', 2: 'شباب وخريجين', 3: 'إعدادي وثانوي'};
    return groups[meeting.classPhase] ?? 'الفرقة الثانية';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.12),
        child: Text(
          index != null ? '${index! + 1}' : '•',
          style: const TextStyle(
            color: AppColors.primaryMaroon,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        member.name ?? '—',
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _groupLabel,
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.primaryMaroon,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.error),
        tooltip: 'إزالة',
        onPressed: onRemove,
      ),
    );
  }
}
