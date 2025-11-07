import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/get_attendance/get_attendance_cubit.dart';
import '../widget/bulk_attendance_dialog.dart';
import '../widget/attendance_table_widget.dart';
import '../../../../../features/profile/repository/i_profile_repository.dart';
import '../../../../authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';

class AttendanceScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const AttendanceScreen({super.key, this.scrollController});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final GetAttendanceCubit _attendanceCubit;
  UserModel? _currentUser;
  String? _selectedClassId;
  bool _isLoadingClasses = false;
  List<ClassModel> _availableClasses = const [];

  @override
  void initState() {
    super.initState();
    _currentUser = sl<IProfileRepository>().user;
    _attendanceCubit = GetAttendanceCubit(
      sl<IAttendanceRepository>(),
      sl<DataRefreshCubit>(),
    );
    _attendanceCubit.fetchAttendance(classId: _selectedClassId);
    _loadClassesIfNeeded();
  }

  @override
  void dispose() {
    _attendanceCubit.close();
    super.dispose();
  }

  Future<void> _loadClassesIfNeeded() async {
    final user = _currentUser;
    if (user == null) return;
    final userRole = user.role;
    final isKhadem = userRole == UserRole.khadem;
    final isSuperAdmin = userRole == UserRole.superAdmin;

    if (!isKhadem && !isSuperAdmin) return;

    setState(() {
      _isLoadingClasses = true;
    });

    final classRepository = sl<IClassRepository>();
    final result = isSuperAdmin
        ? await classRepository.loadClasses()
        : await classRepository.loadMyClasses();

    result.fold(
      (error) {
        print('⚠️ [AttendanceScreen] Failed to load classes: $error');
        if (!mounted) return;
        setState(() {
          _availableClasses = const [];
        });
      },
      (classes) {
        if (!mounted) return;
        setState(() {
          _availableClasses = classes;
          if (_selectedClassId != null &&
              !_availableClasses.any((c) => c.id == _selectedClassId)) {
            _selectedClassId = null;
          }
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoadingClasses = false;
    });
  }

  bool get _shouldShowClassFilter {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role == UserRole.superAdmin) {
      return _availableClasses.isNotEmpty;
    }
    if (user.role == UserRole.khadem) {
      return _availableClasses.length > 1;
    }
    return false;
  }

  Widget _buildClassFilter() {
    if (_isLoadingClasses) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (!_shouldShowClassFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String?>(
        value: _selectedClassId,
        decoration: const InputDecoration(
          labelText: 'اختر فصل',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('كل الفصول'),
          ),
          ..._availableClasses.map(
            (classModel) => DropdownMenuItem<String?>(
              value: classModel.id,
              child: Text(classModel.name),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedClassId = value;
          });
          _attendanceCubit.fetchAttendance(classId: value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocProvider.value(
          value: _attendanceCubit,
          child: Column(
            children: [
              _buildClassFilter(),
              Expanded(
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
                      final Map<String, Map<String, Map<String, bool>>>
                          attendance = {};

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
                          await _attendanceCubit.fetchAttendance(
                              classId: _selectedClassId);
                        },
                        color: AppColors.primaryMaroon,
                        child: SingleChildScrollView(
                          controller: widget.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: AttendanceTableWidget(
                            dates: dates,
                            members: members,
                            attendance: attendance,
                            attendanceRecords: records,
                            onRefresh: () => _attendanceCubit.fetchAttendance(
                                classId: _selectedClassId),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
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
        await _attendanceCubit.fetchAttendance(classId: _selectedClassId);
        print('✅ Attendance refreshed!'); // Debug
      }
    } catch (e) {
      print('Error opening dialog: $e'); // Debug
    }
  }
}
