import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/get_attendance/get_attendance_cubit.dart';
import '../widget/bulk_attendance_dialog.dart';
import '../widget/attendance_table_widget.dart';

class AttendanceScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const AttendanceScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocProvider(
          create: (context) => GetAttendanceCubit(
            sl<IAttendanceRepository>(),
            sl<DataRefreshCubit>(),
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
                // Transform attendance data
                final attendanceData = state.attendance;
                final records = attendanceData.attendanceRecords ?? [];
                final dates = attendanceData.attendanceDates ?? [];

                // Handle empty data
                if (records.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'No attendance records found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                }

                // Get unique member names
                final members = records
                    .where((record) => record.userName != null)
                    .map((record) => record.userName!)
                    .toSet()
                    .toList();

                // Build attendance map: userName -> date -> type -> bool
                final Map<String, Map<String, Map<String, bool>>> attendance =
                    {};

                for (final record in records) {
                  if (record.userName == null ||
                      record.date == null ||
                      record.type == null) {
                    continue;
                  }

                  final userName = record.userName!;
                  final date = record.date!;
                  final type = record.type!;

                  // Initialize nested maps if they don't exist
                  attendance.putIfAbsent(userName, () => {});
                  attendance[userName]!.putIfAbsent(date, () => {});
                  attendance[userName]![date]![type] = true;
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    print('🔄 Refreshing attendance data...'); // Debug
                    await context.read<GetAttendanceCubit>().fetchAttendance();
                  },
                  color: AppColors.primaryMaroon,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: AttendanceTableWidget(
                      dates: dates,
                      members: members,
                      attendance: attendance,
                      onRefresh: () =>
                          context.read<GetAttendanceCubit>().fetchAttendance(),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        // Floating Action Button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              print('✅ Attendance FAB clicked!'); // Debug
              _showBulkAttendanceDialog(context);
            },
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
            elevation: 6,
            heroTag: 'attendanceFAB',
            icon: const Icon(Icons.group_add),
            label: const Text(
              'تسجيل حضور',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showBulkAttendanceDialog(BuildContext context) async {
    print('Opening bulk attendance dialog...'); // Debug
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          print('Building dialog...'); // Debug
          return const BulkAttendanceDialog();
        },
      );

      print('Dialog closed with result: $result'); // Debug
      // Refresh attendance list if attendance was added successfully
      if (result == true && context.mounted) {
        print(
            '🔄 Refreshing attendance after successful submission...'); // Debug
        await context.read<GetAttendanceCubit>().fetchAttendance();
        print('✅ Attendance refreshed!'); // Debug
      }
    } catch (e) {
      print('Error opening dialog: $e'); // Debug
    }
  }
}
