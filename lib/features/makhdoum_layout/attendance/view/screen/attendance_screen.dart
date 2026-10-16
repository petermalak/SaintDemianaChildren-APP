import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saint_demiana_children/features/makhdoum_layout/attendance/viewmodel/attendance_cubit.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../super_admin_&_khadem_layout/attendance/model/attendance_model.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../authentication/model/user_model.dart';
import '../../repository/i_attendance_repository.dart';

class AttendanceScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final String? initialClassId;

  const AttendanceScreen({
    super.key,
    this.scrollController,
    this.initialClassId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<UserClassInfo> _makhdoumClasses = const [];
  String? _selectedClassId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _hydrateMakhdoumClasses();
  }

  void _hydrateMakhdoumClasses() {
    final user = sl<IProfileRepository>().user;
    if (user == null) return;

    final relevantClasses = user.classes
        .where((info) => info.membershipRole == 'makhdoum')
        .toList();

    setState(() {
      _makhdoumClasses = relevantClasses;
      
      if (widget.initialClassId != null && widget.initialClassId!.isNotEmpty) {
        _selectedClassId = widget.initialClassId;
      } else if (_makhdoumClasses.isNotEmpty) {
        _selectedClassId = _makhdoumClasses.first.classId;
      } else if (user.classId != null && user.classId!.isNotEmpty) {
        _selectedClassId = user.classId;
      }
    });
  }

  String? _getClassNameById(String? classId) {
    if (classId == null || classId.isEmpty) {
      return null;
    }
    try {
      return _makhdoumClasses
              .firstWhere((info) => info.classId == classId)
              .className ??
          'فصلي';
    } catch (_) {
      return 'فصلي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleClasses = _makhdoumClasses.length > 1;

    return BlocProvider(
      create: (context) =>
          AttendanceCubit(sl<IAttendanceRepository>())
            ..fetchAttendance(classId: _selectedClassId),
      child: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryMaroon,
              ),
            );
          } else if (state is AttendanceFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AttendanceCubit>().fetchAttendance();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: AppColors.accentWhite),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is AttendanceSuccess) {
            final records = state.attendanceModel.attendanceRecords ?? [];
            final visible = records.where(_matchesFilters).toList();

            return Column(
              children: [
                if (hasMultipleClasses)
                  _buildClassSelector(context),
                if (sl<IProfileRepository>().user?.isPopeAthnasius == true)
                  _buildCurrentCourseLink(context),
                _buildMonthBar(),
                _buildTypeFilters(),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                color: AppColors.textSecondary,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'لا يوجد حضور في هذا الشهر',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AttendanceCubit>().fetchAttendance(
                                  classId: _selectedClassId,
                                );
                          },
                          color: AppColors.primaryMaroon,
                          child: ListView.builder(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              return _buildAttendanceCard(visible[index]);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  bool _matchesFilters(AttendanceRecord record) {
    final parsed = DateTime.tryParse(record.date ?? '');
    if (parsed == null || parsed.year != _month.year || parsed.month != _month.month) {
      return false;
    }
    if (_typeFilter != null && record.type != _typeFilter) return false;
    return true;
  }

  Widget _buildMonthBar() {
    final label = DateFormat('MMMM yyyy', 'ar').format(_month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month - 1);
            }),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month + 1);
            }),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    final levelTwo = sl<IProfileRepository>().user?.popeAthnasiusMeetingData?.studyLevel == 2;
    final types = <String?, String>{
      null: 'الكل',
      'mass': 'قداس',
      'generalMeeting': levelTwo ? 'كتاب المقدس' : 'اجتماع عام',
      'specialMeeting': levelTwo ? 'عقيدة' : 'اجتماع خاص',
      'praise': 'تسبحة',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.entries.map((entry) {
          final selected = _typeFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              selectedColor: AppColors.primaryMaroon,
              labelStyle: TextStyle(
                color: selected ? AppColors.accentWhite : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _typeFilter = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentCourseLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/pope-my-course'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: AppColors.primaryMaroon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المادة الحالية', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('عرض فقط', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context) {
    final className = _getClassNameById(_selectedClassId) ?? 'فصلي';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'فصل الحضور',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            items: _makhdoumClasses
                .map(
                  (info) => DropdownMenuItem(
                    value: info.classId,
                    child: Text(info.className ?? 'فصل بدون اسم'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedClassId = value;
              });
              // Fetch attendance for the new class
              context.read<AttendanceCubit>().fetchAttendance(classId: value);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    IconData icon;
    String typeText;
    Color typeColor;

    final levelTwo = sl<IProfileRepository>().user?.popeAthnasiusMeetingData?.studyLevel == 2;
    switch (record.type) {
      case 'mass':
        icon = Icons.church;
        typeText = 'قداس';
        typeColor = AppColors.primaryMaroon;
        break;
      case 'specialMeeting':
        icon = Icons.star;
        typeText = levelTwo ? 'عقيدة' : 'اجتماع خاص';
        typeColor = AppColors.accentGold;
        break;
      case 'generalMeeting':
        icon = Icons.people;
        typeText = levelTwo ? 'كتاب المقدس' : 'اجتماع عام';
        typeColor = AppColors.primaryBlue;
        break;
      case 'praise':
        icon = Icons.music_note;
        typeText = 'تسبحة';
        typeColor = Colors.purple;
        break;
      default:
        icon = Icons.event;
        typeText = record.type ?? 'غير محدد';
        typeColor = AppColors.textSecondary;
    }

    // Parse and format date
    String formattedDate = record.date ?? '';
    try {
      if (record.date != null && record.date!.isNotEmpty) {
        final date = DateTime.parse(record.date!);
        formattedDate = DateFormat('dd MMMM yyyy', 'ar').format(date);
      }
    } catch (e) {
      formattedDate = record.date ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: typeColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1.clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
