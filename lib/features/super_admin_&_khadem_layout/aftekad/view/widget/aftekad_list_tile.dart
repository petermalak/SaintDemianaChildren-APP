import 'package:flutter/material.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';

import '../../../../../core/constants/app_colors.dart';
import 'add_aftekad_dialog.dart';

class AftekadListTile extends StatelessWidget {
  const AftekadListTile({super.key, required this.aftekad});
  final AftekadModel aftekad;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: aftekad.status == true
              ? LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.1),
                    AppColors.backgroundCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: aftekad.status != true ? AppColors.backgroundCard : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row with status and name
            Row(
              children: [
                // Status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: aftekad.status == true
                        ? AppColors.success
                        : AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aftekad.status == true
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: AppColors.accentWhite,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aftekad.status == true ? 'مكتمل' : 'قيد الانتظار',
                        style: const TextStyle(
                          color: AppColors.accentWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Makhdoum name
                Expanded(
                  child: Text(
                    aftekad.makhdoum?.name ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Action button
                aftekad.status!
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () => _showAddAftekadDialog(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.accentWhite,
                            size: 20,
                          ),
                        ),
                        tooltip: 'إضافة افتقاد',
                      ),
              ],
            ),

            if (aftekad.status == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    // Type
                    if (aftekad.type != null)
                      _buildDetailRow(
                        icon: _getTypeIcon(aftekad.type!),
                        label: 'نوع الافتقاد',
                        value: _getTypeDisplayName(aftekad.type!),
                      ),

                    // Separator
                    if (aftekad.type != null && aftekad.khadem?.name != null)
                      const Divider(height: 16),

                    // Khadem name
                    if (aftekad.khadem?.name != null)
                      _buildDetailRow(
                        icon: Icons.person,
                        label: 'اسم الخادم',
                        value: aftekad.khadem!.name!,
                      ),

                    // Separator
                    if (aftekad.khadem?.name != null &&
                        aftekad.completedDate != null)
                      const Divider(height: 16),

                    // Date
                    if (aftekad.completedDate != null)
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'تاريخ الافتقاد',
                        value: _formatDate(aftekad.completedDate!),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryMaroon,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryMaroon.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(AftekadType type) {
    switch (type) {
      case AftekadType.phone_call:
        return Icons.phone;
      case AftekadType.home_visit:
        return Icons.home;
      case AftekadType.whatsapp_message:
        return Icons.message;
    }
  }

  String _getTypeDisplayName(AftekadType type) {
    switch (type) {
      case AftekadType.phone_call:
        return 'مكالمة هاتفية';
      case AftekadType.home_visit:
        return 'زيارة منزلية';
      case AftekadType.whatsapp_message:
        return 'رسالة واتساب';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddAftekadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAftekadDialog(user: aftekad),
    );
  }
}
