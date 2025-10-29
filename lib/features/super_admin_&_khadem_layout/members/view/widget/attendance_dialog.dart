import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/attendance/viewmodel/add_attendance/add_attendance_cubit.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
                  const Text(
                    'تسجيل حضور',
                    style: TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 18,
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
                          child: const Text('إلغاء'),
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
                          child: const Text('تسجيل الحضور'),
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
    );
  }

  Widget _buildEventSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "اختار الاجتماع",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ الحضور',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
                    style: const TextStyle(fontSize: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "الحاضرين",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
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
            : null);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
