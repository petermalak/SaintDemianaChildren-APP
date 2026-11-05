import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_colors.dart';
import '../cubit/date_filter_cubit.dart';
import '../models/date_filter_state.dart';

/// Date selector widget with chips for each available date
/// Follows Single Responsibility Principle - only displays date chips
class DateFilterSelector extends StatelessWidget {
  const DateFilterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateFilterCubit, DateFilterState>(
      builder: (context, state) {
        if (!state.isDatePickerVisible) {
          return const SizedBox.shrink();
        }

        final datesToShow = state.selectedYear != null
            ? state.getDatesForYear(state.selectedYear!)
            : state.availableDates;

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر تواريخ ${state.selectedYear ?? ""}:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${datesToShow.length} تاريخ متاح',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: datesToShow.map((date) {
                      final dateIso = _dateToIso(date);
                      final isSelected = state.selectedDates.contains(dateIso);

                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 12),
                            const SizedBox(width: 4),
                            Text(_formatDate(date)),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<DateFilterCubit>().toggleDate(dateIso);
                        },
                        backgroundColor: Colors.white,
                        selectedColor:
                            AppColors.primaryMaroon.withOpacity(0.15),
                        checkmarkColor: AppColors.primaryMaroon,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryMaroon
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primaryMaroon
                              : Colors.grey.shade700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
