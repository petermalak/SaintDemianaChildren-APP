import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../model/attendance_model.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/add_attendance/add_attendance_cubit.dart';

class BulkEditAttendanceDialog extends StatelessWidget {
  const BulkEditAttendanceDialog({
    super.key,
    required this.selectedRecords,
  });

  final List<AttendanceRecord> selectedRecords;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddAttendanceCubit(sl<IAttendanceRepository>()),
      child: _BulkEditAttendanceDialogContent(selectedRecords: selectedRecords),
    );
  }
}

class _BulkEditAttendanceDialogContent extends StatefulWidget {
  const _BulkEditAttendanceDialogContent({required this.selectedRecords});

  final List<AttendanceRecord> selectedRecords;

  @override
  State<_BulkEditAttendanceDialogContent> createState() =>
      _BulkEditAttendanceDialogContentState();
}

class _BulkEditAttendanceDialogContentState
    extends State<_BulkEditAttendanceDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEvent;
  DateTime? _selectedDate;
  final _notesController = TextEditingController();
  bool _updateEvent = false;
  bool _updateDate = false;
  bool _updateNotes = false;

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
      maxWidth: 600,
      compactHeightFactor: 0.6,
      regularHeightFactor: 0.7,
    );

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
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectedRecordsInfo(),
                        const SizedBox(height: 20),
                        _buildEventSelector(),
                        const SizedBox(height: 20),
                        _buildDateSelector(),
                        const SizedBox(height: 20),
                        _buildNotesField(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            Icons.edit,
            color: AppColors.accentWhite,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'تعديل سجلات الحضور',
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
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRecordsInfo() {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryMaroon.withValues(alpha: 0.06),
            AppColors.primaryMaroon.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people,
                size: 18, color: AppColors.accentWhite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجلات محددة: ${widget.selectedRecords.length}',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.titleMedium,
                    typography.subtitle,
                    color: AppColors.primaryMaroon,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'سيتم تطبيق التغييرات على جميع السجلات المحددة',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodySmall,
                    typography.label,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;
    const eventOptions = [
      ['praise', 'تسبحة'],
      ['mass', 'قداس'],
      ['generalMeeting', 'اجتماع عام'],
      ['specialMeeting', 'اجتماع خاص'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _updateEvent,
              onChanged: (value) {
                setState(() {
                  _updateEvent = value ?? false;
                  if (!_updateEvent) {
                    _selectedEvent = null;
                  }
                });
              },
              activeColor: AppColors.primaryMaroon,
            ),
            Text(
              "تحديث نوع الاجتماع",
              style: ResponsiveDialogTypography.merge(
                textTheme.titleMedium,
                typography.title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEvent,
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
            filled: true,
            fillColor: AppColors.accentWhite,
            enabled: _updateEvent,
          ),
          items: eventOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option.first,
                  child: Text(
                    option.last,
                    style: ResponsiveDialogTypography.merge(
                      textTheme.bodyMedium,
                      typography.body,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _updateEvent
              ? (value) => setState(() => _selectedEvent = value)
              : null,
          validator: _updateEvent
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى اختيار نوع الاجتماع';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _updateDate,
              onChanged: (value) {
                setState(() {
                  _updateDate = value ?? false;
                  if (!_updateDate) {
                    _selectedDate = null;
                  }
                });
              },
              activeColor: AppColors.primaryMaroon,
            ),
            Text(
              'تحديث التاريخ',
              style: ResponsiveDialogTypography.merge(
                textTheme.titleMedium,
                typography.title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _updateDate ? _selectDate : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _updateDate ? AppColors.accentWhite : Colors.grey[200],
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _updateDate ? AppColors.primaryMaroon : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'اختر التاريخ الجديد',
                  style: ResponsiveDialogTypography.merge(
                    textTheme.bodyMedium,
                    typography.subtitle,
                    color: _updateDate ? AppColors.textPrimary : Colors.grey,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: _updateDate ? null : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _updateNotes,
              onChanged: (value) {
                setState(() {
                  _updateNotes = value ?? false;
                  if (!_updateNotes) {
                    _notesController.clear();
                  }
                });
              },
              activeColor: AppColors.primaryMaroon,
            ),
            Text(
              'تحديث الملاحظات',
              style: ResponsiveDialogTypography.merge(
                textTheme.titleMedium,
                typography.title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          enabled: _updateNotes,
          maxLines: 3,
          style: ResponsiveDialogTypography.merge(
            textTheme.bodyMedium,
            typography.body,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل الملاحظات الجديدة',
            hintStyle: ResponsiveDialogTypography.merge(
              textTheme.bodyMedium,
              typography.body,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
            filled: true,
            fillColor: _updateNotes ? AppColors.accentWhite : Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final mediaSize = MediaQuery.of(context).size;
    final typography = ResponsiveDialogTypography.resolve(mediaSize);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: BlocConsumer<AddAttendanceCubit, AddAttendanceState>(
        listener: (context, state) {
          if (state is AddAttendanceSuccess) {
            sl<DataRefreshCubit>().refreshMultiple({
              RefreshType.attendance,
              RefreshType.stats,
              RefreshType.eftekad,
            });

            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'تم تحديث ${widget.selectedRecords.length} سجل حضور بنجاح'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is AddAttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AddAttendanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryMaroon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: AppColors.accentWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'تحديث السجلات',
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
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_updateEvent && !_updateDate && !_updateNotes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار حقل واحد على الأقل للتحديث'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final attendanceIds = widget.selectedRecords
        .where((r) => r.id != null)
        .map((r) => r.id!)
        .toList();

    if (attendanceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد سجلات صالحة للتحديث'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AddAttendanceCubit>().bulkUpdateAttendance(
          attendanceIds: attendanceIds,
          event: _updateEvent ? _selectedEvent : null,
          date: _updateDate ? _selectedDate : null,
          notes: _updateNotes ? _notesController.text : null,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
