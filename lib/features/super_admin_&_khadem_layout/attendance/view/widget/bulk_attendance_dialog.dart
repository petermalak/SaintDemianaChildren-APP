import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../../../authentication/model/user_model.dart';
import '../../../members/repository/i_members_repository.dart';
import '../../repository/i_attendance_repository.dart';
import '../../viewmodel/add_attendance/add_attendance_cubit.dart';

class BulkAttendanceDialog extends StatelessWidget {
  const BulkAttendanceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddAttendanceCubit(sl<IAttendanceRepository>()),
      child: const _BulkAttendanceDialogContent(),
    );
  }
}

class _BulkAttendanceDialogContent extends StatefulWidget {
  const _BulkAttendanceDialogContent();

  @override
  State<_BulkAttendanceDialogContent> createState() =>
      _BulkAttendanceDialogContentState();
}

class _BulkAttendanceDialogContentState
    extends State<_BulkAttendanceDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String? _selectedEvent;
  DateTime _selectedDate = DateTime.now();
  List<UserModel> _selectedMembers = [];
  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  bool _selectAll = false;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMembers() {
    final membersRepo = sl<IMembersRepository>();
    setState(() {
      // Sort members alphabetically by name
      _allMembers = List.from(membersRepo.members)
        ..sort((a, b) {
          final nameA = a.name?.trim() ?? '';
          final nameB = b.name?.trim() ?? '';
          return nameA.compareTo(nameB);
        });
      _filteredMembers = _allMembers;
      _isLoadingMembers = false;
    });
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        _filteredMembers = _allMembers.where((member) {
          final name = member.name?.toLowerCase() ?? '';
          final email = member.email?.toLowerCase() ?? '';
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // Select all filtered members
        for (var member in _filteredMembers) {
          if (!_selectedMembers.contains(member)) {
            _selectedMembers.add(member);
          }
        }
      } else {
        // Deselect all filtered members
        _selectedMembers.removeWhere((m) => _filteredMembers.contains(m));
      }
    });
  }

  void _toggleMember(UserModel member) {
    setState(() {
      if (_selectedMembers.contains(member)) {
        _selectedMembers.remove(member);
        _selectAll = false;
      } else {
        _selectedMembers.add(member);
        if (_selectedMembers.length == _allMembers.length) {
          _selectAll = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventSelector(),
                      const SizedBox(height: 16),
                      _buildDateSelector(),
                      const SizedBox(height: 20),
                      _buildMembersSelection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Icons.group_add,
            color: AppColors.accentWhite,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'تسجيل حضور جماعي',
            style: TextStyle(
              color: AppColors.accentWhite,
              fontSize: 20,
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

  Widget _buildEventSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "نوع الاجتماع",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
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
            filled: true,
            fillColor: AppColors.accentWhite,
          ),
          items: const [
            DropdownMenuItem(value: 'praise', child: Text('تسبحة')),
            DropdownMenuItem(value: 'mass', child: Text('قداس')),
            DropdownMenuItem(
                value: 'generalMeeting', child: Text('اجتماع عام')),
            DropdownMenuItem(
                value: 'specialMeeting', child: Text('اجتماع خاص')),
          ],
          onChanged: (value) => setState(() => _selectedEvent = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى اختيار نوع الاجتماع';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التاريخ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
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
        ),
      ],
    );
  }

  Widget _buildMembersSelection() {
    if (_isLoadingMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "اختر الأعضاء (${_selectedMembers.length}/${_allMembers.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (_filteredMembers.isNotEmpty)
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                  color: AppColors.primaryMaroon,
                ),
                label: Text(
                  _selectAll ? 'إلغاء المعروض' : 'اختيار المعروض',
                  style: const TextStyle(color: AppColors.primaryMaroon),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن عضو...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.primaryMaroon),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryMaroon, width: 2),
            ),
            filled: true,
            fillColor: AppColors.accentWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        if (_allMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'لا يوجد أعضاء',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else if (_filteredMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد نتائج للبحث',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredMembers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = _filteredMembers[index];
                final isSelected = _selectedMembers.contains(member);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) => _toggleMember(member),
                  title: Text(
                    member.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: member.email != null
                      ? Text(
                          member.email!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                  activeColor: AppColors.primaryMaroon,
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: BlocConsumer<AddAttendanceCubit, AddAttendanceState>(
        listener: (context, state) {
          print('🟢 [Bulk Dialog] State: ${state.runtimeType}'); // Debug
          if (state is AddAttendanceSuccess) {
            print(
                '✅ [Bulk Dialog] Success! Triggering data refresh...'); // Debug

            // Trigger automatic refresh of attendance, stats, and eftekad
            sl<DataRefreshCubit>().refreshMultiple({
              RefreshType.attendance,
              RefreshType.stats,
              RefreshType.eftekad,
            });

            Navigator.pop(context, true); // Return true to trigger refresh
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('تم تسجيل حضور ${_selectedMembers.length} عضو بنجاح'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is AddAttendanceFailure) {
            print('❌ [Bulk Dialog] Error: ${state.errorMessage}'); // Debug
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
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleAddAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: AppColors.accentWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الحضور',
                    style: TextStyle(fontSize: 16),
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
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _handleAddAttendance() async {
    print('🟢 [Dialog] Add Attendance button clicked!'); // Debug

    if (!_formKey.currentState!.validate()) {
      print('⚠️ [Dialog] Form validation failed'); // Debug
      return;
    }

    if (_selectedMembers.isEmpty) {
      print('⚠️ [Dialog] No members selected'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار عضو واحد على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    print('🟢 [Dialog] Calling cubit with:'); // Debug
    print('  - Members: ${_selectedMembers.length}'); // Debug
    print('  - Event: $_selectedEvent'); // Debug
    print('  - Date: $_selectedDate'); // Debug

    context.read<AddAttendanceCubit>().bulkAddAttendance(
          members: _selectedMembers,
          event: _selectedEvent!,
          date: _selectedDate,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
