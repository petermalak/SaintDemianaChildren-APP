import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/date_filter/date_filter.dart';

/// Attendance table widget with improved filtering
/// Follows Single Responsibility Principle - only displays attendance data
class AttendanceTableWidget extends StatelessWidget {
  final List<String> dates;
  final List<String> members;
  final Map<String, Map<String, Map<String, bool>>> attendance;
  final VoidCallback? onRefresh;

  const AttendanceTableWidget({
    super.key,
    required this.dates,
    required this.members,
    required this.attendance,
    this.onRefresh,
  });

  static const Map<String, String> _categoryNames = {
    'praise': 'تسبحة',
    'mass': 'قداس',
    'generalMeeting': 'عام',
    'specialMeeting': 'خاص'
  };

  static const List<String> _categories = [
    'praise',
    'mass',
    'generalMeeting',
    'specialMeeting'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = DateFilterCubit();
        // Initialize with available dates
        final dateTimes =
            dates.map(_parseDateString).whereType<DateTime>().toList();
        cubit.initializeDates(dateTimes);
        return cubit;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DateFilterHeader(
            title: 'سجل الحضور',
            totalItemsCount: members.length,
            itemsLabel: 'عضو',
            onRefresh: onRefresh,
          ),
          const DateFilterQuickActions(),
          const DateFilterSelector(),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildTableWithFilter(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTableWithFilter() {
    return BlocBuilder<DateFilterCubit, DateFilterState>(
      builder: (context, filterState) {
        final filteredDates = filterState.filteredDatesIso;

        if (filteredDates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'اختر تواريخ لعرض الحضور',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return _buildTable(filteredDates);
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Icons.check_circle, Colors.green.shade600, 'حضر'),
          const SizedBox(width: 20),
          _buildLegendItem(
              Icons.remove_circle_outline, Colors.grey.shade400, 'غائب'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<String> filteredDates) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          AppColors.primaryMaroon.withOpacity(0.1),
        ),
        headingRowHeight: 70,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 56,
        border: TableBorder.all(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        columns: [
          const DataColumn(
            label: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'الاسم',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ),
          ),
          for (final date in filteredDates)
            DataColumn(
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDateHeader(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: _categories.map((cat) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: Colors.grey.shade300, width: 0.5),
                        ),
                        child: Text(
                          _categoryNames[cat] ?? cat,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
        rows: members.map((member) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    member,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ),
              for (final date in filteredDates)
                DataCell(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: _categories.map((cat) {
                      final isPresent = attendance[member]?[date]?[cat] == true;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPresent
                              ? Colors.green.shade50
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isPresent
                                ? Colors.green.shade400
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isPresent ? Icons.check : Icons.close,
                            size: 16,
                            color: isPresent
                                ? Colors.green.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDateHeader(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
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
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '$day ${months[month - 1]}';
      }
    } catch (e) {
      // Fallback
    }
    return dateStr;
  }

  DateTime? _parseDateString(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
