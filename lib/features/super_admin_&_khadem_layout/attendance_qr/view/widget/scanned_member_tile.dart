import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../authentication/model/user_model.dart';

class ScannedMemberTile extends StatelessWidget {
  const ScannedMemberTile({
    super.key,
    required this.member,
    required this.onRemove,
  });

  final UserModel member;
  final VoidCallback onRemove;

  String? get _phaseSubtitle {
    final phase = member.popeAthnasiusMeetingData?.classPhase;
    if (phase == null) return null;
    return 'المرحلة: $phase';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.15),
        child: const Icon(Icons.person,
            color: AppColors.primaryMaroon, size: 22),
      ),
      title: Text(
        member.name ?? '—',
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.id != null && member.id!.isNotEmpty)
            Text(
              member.id!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          if (_phaseSubtitle != null)
            Text(
              _phaseSubtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primaryMaroon,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.error),
        tooltip: 'إزالة',
        onPressed: onRemove,
      ),
    );
  }
}
