import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/get_attendance/get_attendance_cubit.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetAttendanceCubit(
        sl<IAttendanceRepository>(),
      )..fetchAttendance(),
      child: BlocBuilder<GetAttendanceCubit, GetAttendanceState>(
        builder: (context, state) {
          if (state is GetAttendanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GetAttendanceFailure) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  height: 250,
                  child: Center(
                      child: Text(state.errorMessage,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)))),
            );
          } else if (state is GetAttendanceSuccess) {
            // Mocked static data for demonstration
            final dates = ['12/10/2025', '5/10/2025'];
            final members = ['John Doe', 'Jane Smith'];
            final attendance = {
              'John Doe': {
                '12/10/2025': {
                  'tsb7a': true,
                  'odas': false,
                  'general': true,
                  'private': false,
                },
                '5/10/2025': {
                  'tsb7a': true,
                  'odas': true,
                  'general': false,
                  'private': true,
                },
              },
              'Jane Smith': {
                '12/10/2025': {
                  'tsb7a': false,
                  'odas': true,
                  'general': false,
                  'private': true,
                },
                '5/10/2025': {
                  'tsb7a': true,
                  'odas': false,
                  'general': true,
                  'private': false,
                },
              },
            };
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  AttendanceTable(
                    dates: dates,
                    members: members,
                    attendance: attendance,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class AttendanceTable extends StatefulWidget {
  final List<String> dates;
  final List<String> categories = ['tsb7a', 'odas', 'general', 'private'];
  final List<String> members;
  final Map<String, Map<String, Map<String, bool>>> attendance;

  AttendanceTable({
    super.key,
    required this.dates,
    required this.members,
    required this.attendance,
  });

  @override
  State<AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<AttendanceTable> {
  Set<String> selectedDates = <String>{};

  @override
  void initState() {
    super.initState();
    // Initially show all dates
    selectedDates = widget.dates.toSet();
  }

  List<String> get filteredDates {
    return selectedDates.isEmpty ? widget.dates : selectedDates.toList();
  }

  void toggleDateSelection(String date) {
    setState(() {
      if (selectedDates.contains(date)) {
        selectedDates.remove(date);
      } else {
        selectedDates.add(date);
      }
      // If no dates selected, show all dates
      if (selectedDates.isEmpty) {
        selectedDates = widget.dates.toSet();
      }
    });
  }

  void selectAllDates() {
    setState(() {
      selectedDates = widget.dates.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date filter buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              // "All Dates" button
              FilterChip(
                label: const Text('All Dates'),
                selected: selectedDates.length == widget.dates.length,
                onSelected: (selected) {
                  selectAllDates();
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade700,
              ),
              // Individual date buttons
              ...widget.dates.map((date) => FilterChip(
                    label: Text(date),
                    selected: selectedDates.contains(date),
                    onSelected: (selected) {
                      toggleDateSelection(date);
                    },
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade700,
                  )),
            ],
          ),
        ),
        // Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              // Top row: empty cell + date headers (each with 4 sub-columns)
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: const Text('Name',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final date in filteredDates)
                    TableCell(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final cat in widget.categories)
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(cat,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Member rows
              for (final member in widget.members)
                TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.centerLeft,
                      child: Text(member,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    for (final date in filteredDates)
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final cat in widget.categories)
                              Container(
                                width: 50,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: widget.attendance[member]?[date]?[cat] ==
                                        true
                                    ? const Text('+',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green))
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
