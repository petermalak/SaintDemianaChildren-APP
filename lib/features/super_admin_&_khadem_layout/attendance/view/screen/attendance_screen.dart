import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../repository/i_attendance_repository.dart';
import '../../model/attendance_model.dart';
import '../../viewmodel/get_attendance/get_attendance_cubit.dart';
import '../widget/bulk_attendance_dialog.dart';
import '../widget/attendance_table_widget.dart';
import '../../../../../features/profile/repository/i_profile_repository.dart';
import '../../../../authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/manage_assignments_dialog.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_assignment_model.dart';
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
  List<AssignmentUser> _khademOptions = const [];
  String? _selectedKhademId;
  bool _isLoadingAssignments = false;
  ScrollController? _internalScrollController;

  static const Map<String, String> _attendanceTypeLabels = {
    'praise': 'تسبحة',
    'mass': 'قداس',
    'generalMeeting': 'اجتماع عام',
    'specialMeeting': 'اجتماع خاص',
  };

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _internalScrollController = ScrollController();
    }
    _currentUser = sl<IProfileRepository>().user;
    if (_currentUser?.role == UserRole.khadem) {
      _selectedKhademId = _currentUser?.id;
      if (_currentUser != null) {
        _khademOptions = [_buildUserOptionFromUser(_currentUser!)];
      }
    }
    _attendanceCubit = GetAttendanceCubit(
      sl<IAttendanceRepository>(),
      sl<DataRefreshCubit>(),
    );
    _attendanceCubit.fetchAttendance(
      classId: _selectedClassId,
      khademId: _selectedKhademId,
    );
    _loadClassesIfNeeded();
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
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

    await result.fold(
      (error) async {
        print('⚠️ [AttendanceScreen] Failed to load classes: $error');
        if (!mounted) return;
        setState(() {
          _availableClasses = const [];
          _khademOptions = const [];
        });
      },
      (classes) async {
        if (!mounted) return;
        setState(() {
          _availableClasses = classes;
          if (_selectedClassId != null &&
              !_availableClasses.any((c) => c.id == _selectedClassId)) {
            _selectedClassId = null;
          }
          if (_selectedClassId == null && classes.isNotEmpty && isKhadem) {
            _selectedClassId = classes.first.id;
          }
        });
        if (_selectedClassId != null) {
          await _loadAssignmentsForClass(
            _selectedClassId!,
            resetSelection: isSuperAdmin,
          );
        } else {
          _resetKhademOptionsForAllClasses();
          _attendanceCubit.fetchAttendance(
            classId: null,
            khademId: _selectedKhademId,
          );
        }
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

  AssignmentUser _buildUserOptionFromUser(UserModel user) {
    return AssignmentUser(
      id: user.id ?? '',
      name: user.name,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role?.name,
    );
  }

  void _resetKhademOptionsForAllClasses() {
    final user = _currentUser;
    if (user?.role == UserRole.khadem) {
      final selfOption = _buildUserOptionFromUser(user!);
      setState(() {
        _khademOptions = [selfOption];
        _selectedKhademId = selfOption.id;
      });
    } else {
      setState(() {
        _khademOptions = const [];
        _selectedKhademId = null;
      });
    }
  }

  Future<void> _loadAssignmentsForClass(
    String classId, {
    bool resetSelection = false,
  }) async {
    setState(() {
      _isLoadingAssignments = true;
    });

    final classRepository = sl<IClassRepository>();
    final result = await classRepository.loadClassAssignments(classId);

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() {
          _isLoadingAssignments = false;
          _khademOptions = const [];
        });
        _attendanceCubit.fetchAttendance(
          classId: classId,
          khademId: _selectedKhademId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (assignments) {
        final options = [...assignments.khadems];
        final user = _currentUser;
        if (user?.role == UserRole.khadem) {
          final selfOption = _buildUserOptionFromUser(user!);
          if (!options.any((option) => option.id == selfOption.id)) {
            options.add(selfOption);
          }
        }

        final optionIds = options.map((option) => option.id).toSet();
        String? nextSelected = _selectedKhademId;

        if (user?.role == UserRole.khadem) {
          nextSelected = user?.id;
        } else {
          if (resetSelection ||
              nextSelected == null ||
              !optionIds.contains(nextSelected)) {
            nextSelected = null;
          }
        }

        setState(() {
          _khademOptions = options;
          _selectedKhademId = nextSelected;
          _isLoadingAssignments = false;
        });

        _attendanceCubit.fetchAttendance(
          classId: classId,
          khademId: _selectedKhademId,
        );
      },
    );
  }

  Future<void> _refreshAttendance() {
    return _attendanceCubit.fetchAttendance(
      classId: _selectedClassId,
      khademId: _selectedKhademId,
    );
  }

  Future<void> _onClassFilterChanged(String? value) async {
    if (_selectedClassId == value) return;
    setState(() {
      _selectedClassId = value;
    });

    if (value == null) {
      _resetKhademOptionsForAllClasses();
      _attendanceCubit.fetchAttendance(
        classId: null,
        khademId: _selectedKhademId,
      );
    } else {
      await _loadAssignmentsForClass(
        value,
        resetSelection: _currentUser?.role == UserRole.superAdmin,
      );
    }
  }

  bool get _shouldShowKhademFilter {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role == UserRole.khadem) return true;
    if (user.role == UserRole.superAdmin) {
      return _khademOptions.isNotEmpty || _isLoadingAssignments;
    }
    return false;
  }

  bool get _canManageAssignments {
    final user = _currentUser;
    if (user == null) return false;
    return user.role == UserRole.khadem || user.role == UserRole.superAdmin;
  }

  Future<void> _openManageAssignmentsDialog() async {
    final classId = _selectedClassId;
    if (classId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ManageAssignmentsDialog(
        availableClasses: _availableClasses,
        initialClassId: classId,
      ),
    );

    if (result == true) {
      await _loadAssignmentsForClass(
        classId,
        resetSelection: _currentUser?.role == UserRole.superAdmin,
      );
    }
  }

  Widget _buildFilterCard(GetAttendanceState state) {
    final bool showLoader = _isLoadingClasses || _isLoadingAssignments;
    final attendanceData =
        state is GetAttendanceSuccess ? state.attendance : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double fieldWidth;
        if (maxWidth >= 900) {
          fieldWidth = (maxWidth - 32) / 3;
        } else if (maxWidth >= 600) {
          fieldWidth = (maxWidth - 16) / 2;
        } else {
          fieldWidth = maxWidth;
        }
        fieldWidth = fieldWidth.clamp(220, maxWidth);

        return Card(
          elevation: 0,
          color: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات العرض',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'حدد الفصل والخادم للحصول على رؤية أوضح لسجلات الحضور.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_canManageAssignments)
                      TextButton.icon(
                        onPressed:
                            _selectedClassId == null || _isLoadingAssignments
                                ? null
                                : _openManageAssignmentsDialog,
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text('توزيع المخدومين'),
                      ),
                  ],
                ),
                if (showLoader) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (_shouldShowClassFilter)
                      SizedBox(
                        width: fieldWidth,
                        child: _buildClassDropdownField(),
                      ),
                    if (_shouldShowKhademFilter)
                      SizedBox(
                        width: fieldWidth,
                        child: _buildKhademField(),
                      ),
                  ],
                ),
                if (attendanceData != null) ...[
                  const SizedBox(height: 16),
                  _buildAttendanceSummary(attendanceData),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassDropdownField() {
    return DropdownButtonFormField<String?>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'اختر فصل',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      isExpanded: true,
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
      onChanged: _isLoadingAssignments || _isLoadingClasses
          ? null
          : (value) => _onClassFilterChanged(value),
    );
  }

  Widget _buildKhademField() {
    final user = _currentUser;
    if (user?.role == UserRole.khadem) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الخادم',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(user?.name ?? 'الخادم'),
      );
    }

    return DropdownButtonFormField<String?>(
      value: _selectedKhademId,
      decoration: const InputDecoration(
        labelText: 'اختر خادم',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('جميع الخدام'),
        ),
        ..._khademOptions.map(
          (option) => DropdownMenuItem<String?>(
            value: option.id,
            child: Text(option.name ?? 'خادم بدون اسم'),
          ),
        ),
      ],
      onChanged: _isLoadingAssignments
          ? null
          : (value) {
              setState(() {
                _selectedKhademId = value;
              });
              _attendanceCubit.fetchAttendance(
                classId: _selectedClassId,
                khademId: _selectedKhademId,
              );
            },
    );
  }

  Widget _buildAttendanceSummary(AttendanceModel data) {
    final records = data.attendanceRecords ?? [];
    final datesCount = data.attendanceDates?.length ?? 0;
    final memberIds = <String>{};
    final typeCounts = <String, int>{};

    for (final record in records) {
      final memberKey = record.userId?.isNotEmpty == true
          ? record.userId!
          : (record.userName ?? '');
      if (memberKey.isNotEmpty) {
        memberIds.add(memberKey);
      }
      if (record.type != null && record.type!.isNotEmpty) {
        typeCounts.update(
          record.type!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final membersCount = memberIds.length;
    final totalRecords = records.length;
    final topTypeEntry = typeCounts.entries.isEmpty
        ? null
        : typeCounts.entries.reduce(
            (value, element) => element.value > value.value ? element : value,
          );
    final topTypeLabel = topTypeEntry == null
        ? '—'
        : _attendanceTypeLabels[topTypeEntry.key] ?? topTypeEntry.key;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryChip(
          icon: Icons.group,
          label: 'إجمالي الأعضاء',
          value: membersCount.toString(),
        ),
        _buildSummaryChip(
          icon: Icons.event_available,
          label: 'الأيام المسجلة',
          value: datesCount.toString(),
        ),
        _buildSummaryChip(
          icon: Icons.assignment_turned_in,
          label: 'عدد السجلات',
          value: totalRecords.toString(),
        ),
        _buildSummaryChip(
          icon: Icons.star,
          label: 'أكثر اجتماع نشاطاً',
          value: topTypeLabel,
        ),
      ],
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryMaroon),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSliver(GetAttendanceState state) {
    if (state is GetAttendanceLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is GetAttendanceFailure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(state.errorMessage),
      );
    }

    if (state is GetAttendanceSuccess) {
      final attendanceData = state.attendance;
      final records = attendanceData.attendanceRecords ?? [];
      final dates = attendanceData.attendanceDates ?? [];

      if (records.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(),
        );
      }

      final members = _extractMemberNames(records);
      final attendanceMatrix = _buildAttendanceMatrix(records);

      return SliverToBoxAdapter(
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AttendanceTableWidget(
              dates: dates,
              members: members,
              attendance: attendanceMatrix,
              attendanceRecords: records,
              onRefresh: _refreshAttendance,
            ),
          ),
        ),
      );
    }

    return const SliverFillRemaining(
      hasScrollBody: false,
      child: SizedBox.shrink(),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'تعذر تحميل الحضور',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        const Text(
          'لا توجد سجلات حضور',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'جرّب تغيير عوامل التصفية أو أضف سجلاً جديداً.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<String> _extractMemberNames(List<AttendanceRecord> records) {
    final orderedNames = <String>{};
    for (final record in records) {
      if (record.userName != null && record.userName!.isNotEmpty) {
        orderedNames.add(record.userName!);
      }
    }
    return orderedNames.toList();
  }

  Map<String, Map<String, Map<String, bool>>> _buildAttendanceMatrix(
      List<AttendanceRecord> records) {
    final result = <String, Map<String, Map<String, bool>>>{};

    for (final record in records) {
      final userName = record.userName;
      final date = record.date;
      final type = record.type;
      if (userName == null || date == null || type == null) continue;

      final userMap =
          result.putIfAbsent(userName, () => <String, Map<String, bool>>{});
      final dateMap = userMap.putIfAbsent(date, () => <String, bool>{});
      dateMap[type] = true;
    }

    return result;
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showBulkAttendanceDialog(context),
      backgroundColor: AppColors.primaryMaroon,
      foregroundColor: AppColors.accentWhite,
      elevation: 6,
      heroTag: 'attendanceFAB',
      icon: const Icon(Icons.group_add),
      label: const Text(
        'تسجيل حضور',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _attendanceCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        floatingActionButton: _buildFloatingActionButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: BlocBuilder<GetAttendanceCubit, GetAttendanceState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: _refreshAttendance,
                color: AppColors.primaryMaroon,
                child: CustomScrollView(
                  controller: _effectiveScrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _buildFilterCard(state),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: _buildAttendanceSliver(state),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showBulkAttendanceDialog(BuildContext context) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const BulkAttendanceDialog(),
      );

      if (result == true && context.mounted) {
        await _attendanceCubit.fetchAttendance(
          classId: _selectedClassId,
          khademId: _selectedKhademId,
        );
      }
    } catch (e) {
      debugPrint('Error opening bulk attendance dialog: $e');
    }
  }
}
