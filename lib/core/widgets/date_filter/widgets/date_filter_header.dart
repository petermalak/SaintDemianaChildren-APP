import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_colors.dart';
import '../cubit/date_filter_cubit.dart';
import '../models/date_filter_state.dart';

/// Header widget for date filtering with year selector
/// Follows Single Responsibility Principle - only displays header info
class DateFilterHeader extends StatelessWidget {
  final String title;
  final int totalItemsCount;
  final String itemsLabel;
  final VoidCallback? onRefresh;

  const DateFilterHeader({
    super.key,
    required this.title,
    required this.totalItemsCount,
    required this.itemsLabel,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateFilterCubit, DateFilterState>(
      builder: (context, state) {
        final years = state.availableYears;
        final selectedCount = state.selectedDates.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentWhite,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const Spacer(),
                  if (years.isNotEmpty)
                    _buildYearSelector(context, years, state),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.calendar_month,
                    '${state.availableDates.length} تاريخ',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.people,
                    '$totalItemsCount $itemsLabel',
                  ),
                  const Spacer(),
                  if (onRefresh != null)
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تحديث البيانات',
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.primaryMaroon,
                        backgroundColor:
                            AppColors.primaryMaroon.withOpacity(0.1),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'مختار: $selectedCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMaroon,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector(
      BuildContext context, List<int> years, DateFilterState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryMaroon),
      ),
      child: DropdownButton<int>(
        value: state.selectedYear,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.primaryMaroon,
          size: 20,
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryMaroon,
        ),
        items: years.map((year) {
          final datesInYear = state.getDatesForYear(year).length;
          return DropdownMenuItem(
            value: year,
            child: Text('$year ($datesInYear تاريخ)'),
          );
        }).toList(),
        onChanged: (year) {
          if (year != null) {
            context.read<DateFilterCubit>().changeYear(year);
          }
        },
      ),
    );
  }
}
