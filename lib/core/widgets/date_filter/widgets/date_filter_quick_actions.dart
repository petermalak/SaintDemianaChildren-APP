import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_colors.dart';
import '../cubit/date_filter_cubit.dart';
import '../models/date_filter_state.dart';

/// Quick action buttons for common date filter operations
/// Follows Single Responsibility Principle - only handles quick actions
class DateFilterQuickActions extends StatelessWidget {
  const DateFilterQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateFilterCubit, DateFilterState>(
      builder: (context, state) {
        final cubit = context.read<DateFilterCubit>();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.event,
                      label: 'آخر 4 أيام',
                      onPressed: () => cubit.selectRecentDates(4),
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.calendar_view_month,
                      label: 'شهرين',
                      onPressed: () => cubit.selectRecentDates(8),
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.done_all,
                      label: 'كل السنة',
                      onPressed: cubit.selectAllInYear,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: state.isDatePickerVisible
                          ? Icons.expand_less
                          : Icons.expand_more,
                      label:
                          state.isDatePickerVisible ? 'إخفاء' : 'اختر تواريخ',
                      onPressed: cubit.toggleDatePicker,
                      color: AppColors.primaryMaroon,
                      filled: state.isDatePickerVisible,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    context,
                    icon: Icons.clear,
                    label: 'مسح',
                    onPressed: state.selectedDates.isNotEmpty
                        ? cubit.clearSelection
                        : null,
                    color: Colors.red.shade600,
                    minWidth: 80,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool filled = false,
    double? minWidth,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: filled ? Colors.white : color,
        backgroundColor: filled ? color : null,
        disabledForegroundColor: Colors.grey,
        side: BorderSide(
          color: onPressed != null ? color : Colors.grey.shade400,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: minWidth != null ? 12 : 8,
        ),
        minimumSize: minWidth != null ? Size(minWidth, 0) : null,
      ),
    );
  }
}
