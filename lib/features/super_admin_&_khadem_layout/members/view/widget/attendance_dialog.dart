import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/viewmodel/add_attendance/add_attendance_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../../super_admin_&_khadem_layout/attendance/repository/i_attendance_repository.dart';

class AddAttendanceDialog extends StatelessWidget {
  final List<UserModel> members;

  const AddAttendanceDialog({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddAttendanceCubit(sl<IAttendanceRepository>()),
      child: _AddAttendanceDialogContent(members: members),
    );
  }
}

class _AddAttendanceDialogContent extends StatefulWidget {
  final List<UserModel> members;

  const _AddAttendanceDialogContent({required this.members});

  @override
  State<_AddAttendanceDialogContent> createState() =>
      _AddAttendanceDialogContentState();
}

class _AddAttendanceDialogContentState
    extends State<_AddAttendanceDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEvent;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _shouldAddScore = true;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final sizing = ResponsiveDialogUtils.buildSizing(
      mediaSize,
      minWidth: 420,
      maxWidth: 1280,
      compactHeightFactor: 0.64,
      regularHeightFactor: 0.78,
    );
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: sizing.toConstraints(lockWidth: true),
        child: SizedBox(
          width: sizing.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: AppColors.accentWhite,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'تسجيل حضور',
                      style: ResponsiveDialogTypography.merge(
                        textTheme.titleLarge,
                        typography.headline,
                        color: AppColors.accentWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.accentWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEventSelector(),
                        const SizedBox(height: 12),
                        _buildDateSelector(),
                        const SizedBox(height: 16),
                        _buildScoreToggle(),
                        const SizedBox(height: 16),
                        _buildScoreToggle(),
                        const SizedBox(height: 16),
                        CustomTextField(
                            controller: _notesController, labelText: 'Note'),
                        const SizedBox(height: 12),
                        _buildMembersField(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: BlocConsumer<AddAttendanceCubit, AddAttendanceState>(
                  listener: (context, state) {
                    print(
                        '🔴 [OLD Dialog] State changed: ${state.runtimeType}'); // Debug
                    if (state is AddAttendanceSuccess) {
                      print(
                          '✅ [OLD Dialog] Success! Triggering data refresh...'); // Debug

                      // Trigger automatic refresh of attendance, stats, and eftekad
                      sl<DataRefreshCubit>().refreshMultiple({
                        RefreshType.attendance,
                        RefreshType.stats,
                        RefreshType.eftekad,
                      });

                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تسجيل الحضور بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (state is AddAttendanceFailure) {
                      print(
                          '❌ [OLD Dialog] Failure: ${state.errorMessage}'); // Debug
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AddAttendanceLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'إلغاء',
                              style: ResponsiveDialogTypography.merge(
                                textTheme.titleMedium,
                                typography.button,
                                color: AppColors.primaryMaroon,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleAddAttendance,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: AppColors.accentWhite,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'تسجيل الحضور',
                              style: ResponsiveDialogTypography.merge(
                                textTheme.titleMedium,
                                typography.button,
                                color: AppColors.accentWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "اختار الاجتماع",
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          return DropdownButtonFormField<String>(
            value: _selectedEvent,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primaryMaroon, width: 2),
              ),
            ),
            items: ['praise', 'mass', 'generalMeeting', 'specialMeeting']
                .map((event) {
              return DropdownMenuItem(
                value: event,
                child: Text(event),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedEvent = value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى اختيار العضو';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildDateSelector() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ الحضور',
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          return InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentWhite,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primaryMaroon),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_selectedDate),
                    style: ResponsiveDialogTypography.merge(
                      textTheme.bodyMedium,
                      typography.subtitle,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersField() {
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الحاضرين",
          style: ResponsiveDialogTypography.merge(
            textTheme.titleMedium,
            typography.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: widget.members.length,
            itemBuilder: (BuildContext context, int index) {
              return Text(
                widget.members[index].name!,
                style: ResponsiveDialogTypography.merge(
                  textTheme.bodyMedium,
                  typography.body,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _handleAddAttendance() async {
    print('🔴 [OLD Dialog] تسجيل حضور clicked!'); // Debug

    if (!_formKey.currentState!.validate()) {
      print('⚠️ [OLD Dialog] Form validation failed'); // Debug
      return;
    }

    if (_selectedEvent == null) {
      print('⚠️ [OLD Dialog] No event selected'); // Debug
      return;
    }

    print('🔴 [OLD Dialog] Calling cubit with:'); // Debug
    print('  - Members: ${widget.members.length}'); // Debug
    print('  - Event: $_selectedEvent'); // Debug
    print('  - Date: $_selectedDate'); // Debug

    context.read<AddAttendanceCubit>().bulkAddAttendance(
        members: widget.members,
        event: _selectedEvent!,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        addScore: _shouldAddScore);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildScoreToggle() {
    final textTheme = Theme.of(context).textTheme;
    final typography = ResponsiveDialogTypography.resolve(
      MediaQuery.of(context).size,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'احتساب نقاط الحضور',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.titleMedium,
                    typography.title,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أوقف هذا الخيار إذا لم ترغب في إضافة نقاط لهذا الحضور.',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodySmall,
                    typography.label,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _shouldAddScore,
            activeColor: AppColors.primaryMaroon,
            onChanged: (value) {
              setState(() => _shouldAddScore = value);
            },
          ),
        ],
      ),
    );
  }
}
