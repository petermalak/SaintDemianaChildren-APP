import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/viewmodel/get_aftekad/get_aftekad_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/aftekad/model/aftekad_model.dart';
import 'package:intl/intl.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_assignment_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/manage_assignments_dialog.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/data_refresh_cubit.dart';
import '../../repository/i_aftekad_repository.dart';
import '../widget/aftekad_list_tile.dart';

/// Aftekad screen with improved date filtering
/// Follows Single Responsibility Principle - only manages aftekad display
class AftekadScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const AftekadScreen({super.key, this.scrollController});

  @override
  State<AftekadScreen> createState() => _AftekadScreenState();
}

class _AftekadScreenState extends State<AftekadScreen> {
  late GetAftekadCubit _aftekadCubit;
  List<DateTime> _fridayDates = [];
  String? _currentSelectedDate;
  UserModel? _currentUser;
  List<UserClassInfo> _assignedClasses = const [];
  List<UserClassInfo> _classOptions = const [];
  String? _selectedClassId;
  bool _isLoadingClasses = false;
  AftekadSortOption _selectedSortOption = AftekadSortOption.consecutiveMissed;
  bool _isSortDescending = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ClassAssignmentsModel? _currentAssignments;
  List<AssignmentUser> _khademOptions = const [];
  String? _selectedKhademId;
  bool _isLoadingAssignments = false;
  ScrollController? _internalScrollController;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _internalScrollController = ScrollController();
    }
    _generateFridayDates();
    _aftekadCubit =
        GetAftekadCubit(sl<IAftekadRepository>(), sl<DataRefreshCubit>());

    _currentUser = sl<IProfileRepository>().user;
    _assignedClasses = (_currentUser?.classes ?? const [])
        .where((info) => info.classId.isNotEmpty)
        .toList();
    _classOptions = _assignedClasses;
    if (_currentUser?.role == UserRole.khadem) {
      _selectedKhademId = _currentUser?.id;
      if (_currentUser?.id != null) {
        _khademOptions = [
          AssignmentUser(
            id: _currentUser!.id!,
            name: _currentUser!.name,
            email: _currentUser!.email,
            phoneNumber: _currentUser!.phoneNumber,
            role: 'khadem',
          ),
        ];
      }
    }
    _loadClassOptions();

    _searchController.addListener(_onSearchChanged);

    // Load initial data
    if (_fridayDates.isNotEmpty && _currentUser?.id != null) {
      final mostRecentFriday = _fridayDates.first;
      final formattedDate = DateFormat('yyyy-MM-dd').format(mostRecentFriday);
      _currentSelectedDate = formattedDate;
      _aftekadCubit.getAftekad(
        formattedDate,
        khademId: _selectedKhademId,
        classId: _selectedClassId,
      );
    }
  }

  @override
  void dispose() {
    _internalScrollController?.dispose();
    _aftekadCubit.close();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _generateFridayDates() {
    final startDate = DateTime(2025, 10, 3); // 3-10-2025
    final endDate = DateTime.now();

    DateTime current = startDate;

    // Find the first Friday from start date
    while (current.weekday != DateTime.friday) {
      current = current.add(const Duration(days: 1));
    }

    // Generate all Fridays until current date
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      _fridayDates.add(current);
      current = current.add(const Duration(days: 7));
    }

    // Sort in descending order (most recent first)
    _fridayDates.sort((a, b) => b.compareTo(a));
  }

  Future<void> _loadClassOptions() async {
    final userRole = _currentUser?.role;
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

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _isLoadingClasses = false;
          _classOptions = _assignedClasses;
        });
        _resetKhademFilterForAllClasses();
      },
      (classList) async {
        final mapped = classList
            .map(
              (ClassModel classModel) => UserClassInfo(
                classId: classModel.id,
                className: classModel.name,
                classDescription: classModel.description,
                membershipRole: 'khadem',
                isActive: classModel.isActive,
                joinedAt: classModel.createdAt,
              ),
            )
            .toList();

        final combined = {
          for (final info in [..._assignedClasses, ...mapped])
            info.classId: info,
        };

        String? nextClassId = _selectedClassId;
        if (nextClassId != null && !combined.containsKey(nextClassId)) {
          nextClassId = null;
        }
        if (nextClassId == null && isKhadem && combined.isNotEmpty) {
          nextClassId = combined.values.first.classId;
        }

        setState(() {
          _classOptions = combined.values.toList();
          _selectedClassId = nextClassId;
          _isLoadingClasses = false;
        });

        if (nextClassId != null) {
          await _loadAssignmentsForClass(
            nextClassId,
            resetSelection: isSuperAdmin,
          );
        } else {
          _resetKhademFilterForAllClasses();
          if (_currentSelectedDate != null) {
            _aftekadCubit.getAftekad(
              _currentSelectedDate!,
              khademId: _selectedKhademId,
              classId: _selectedClassId,
            );
          }
        }
      },
    );
  }

  AssignmentUser? _assignmentUserFromCurrentUser() {
    final user = _currentUser;
    if (user?.id == null) return null;
    return AssignmentUser(
      id: user!.id!,
      name: user.name,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role?.name,
    );
  }

  void _resetKhademFilterForAllClasses() {
    final user = _currentUser;
    if (!mounted) return;

    if (user?.role == UserRole.khadem) {
      final selfOption = _assignmentUserFromCurrentUser();
      if (selfOption != null) {
        setState(() {
          _khademOptions = [selfOption];
          _selectedKhademId = selfOption.id;
          _currentAssignments = null;
        });
      }
    } else {
      setState(() {
        _khademOptions = const [];
        _selectedKhademId = null;
        _currentAssignments = null;
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
          _currentAssignments = null;
          _khademOptions = const [];
        });
        if (_currentSelectedDate != null) {
          _aftekadCubit.getAftekad(
            _currentSelectedDate!,
            khademId: _selectedKhademId,
            classId: _selectedClassId,
          );
        }
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
        final selfOption = _assignmentUserFromCurrentUser();
        if (user?.role == UserRole.khadem && selfOption != null) {
          if (!options.any((option) => option.id == selfOption.id)) {
            options.add(selfOption);
          }
        }

        final optionIds = options.map((option) => option.id).toSet();
        String? nextSelected = _selectedKhademId;

        if (user?.role == UserRole.khadem) {
          nextSelected = user?.id;
        } else if (resetSelection ||
            nextSelected == null ||
            !optionIds.contains(nextSelected)) {
          nextSelected = null;
        }

        setState(() {
          _currentAssignments = assignments;
          _khademOptions = options;
          _selectedKhademId = nextSelected;
          _isLoadingAssignments = false;
        });

        if (_currentSelectedDate != null) {
          _aftekadCubit.getAftekad(
            _currentSelectedDate!,
            khademId: _selectedKhademId,
            classId: _selectedClassId,
          );
        }
      },
    );
  }

  Future<void> _onClassSelectionChanged(String? classId) async {
    if (_selectedClassId == classId) return;
    setState(() {
      _selectedClassId = classId;
    });

    if (classId == null || classId.isEmpty) {
      _resetKhademFilterForAllClasses();
      if (_currentSelectedDate != null) {
        _aftekadCubit.getAftekad(
          _currentSelectedDate!,
          khademId: _selectedKhademId,
          classId: _selectedClassId,
        );
      }
    } else {
      await _loadAssignmentsForClass(
        classId,
        resetSelection: _currentUser?.role == UserRole.superAdmin,
      );
    }
  }

  void _onKhademSelectionChanged(String? khademId) {
    setState(() {
      _selectedKhademId = khademId;
    });
    if (_currentSelectedDate != null) {
      _aftekadCubit.getAftekad(
        _currentSelectedDate!,
        khademId: _selectedKhademId,
        classId: _selectedClassId,
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

  Widget _buildKhademFilterDropdown() {
    final user = _currentUser;
    if (user == null || !_shouldShowKhademFilter) {
      return const SizedBox.shrink();
    }

    if (user.role == UserRole.khadem) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الخادم',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(user.name ?? 'الخادم'),
      );
    }

    final options = _khademOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingAssignments)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        DropdownButtonFormField<String?>(
          value: _selectedKhademId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'اختر خادم',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('جميع الخدام'),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String?>(
                value: option.id,
                child: Text(option.name ?? 'خادم بدون اسم'),
              ),
            ),
          ],
          onChanged: _isLoadingAssignments ? null : _onKhademSelectionChanged,
        ),
      ],
    );
  }

  bool get _canManageAssignments {
    final user = _currentUser;
    if (user == null) return false;
    return user.role == UserRole.khadem || user.role == UserRole.superAdmin;
  }

  Widget _buildAssignmentsButton() {
    if (!_canManageAssignments || _selectedClassId == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _isLoadingAssignments ? null : _openManageAssignmentsDialog,
        icon: const Icon(Icons.manage_accounts),
        label: const Text('توزيع المخدومين'),
      ),
    );
  }

  Future<void> _openManageAssignmentsDialog() async {
    final classId = _selectedClassId;
    if (classId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ManageAssignmentsDialog(
        availableClasses: _classOptions
            .map(
              (info) => ClassModel(
                id: info.classId,
                name: info.className ?? '',
                description: info.classDescription,
                isActive: info.isActive ?? true,
                maxMembers: null,
                location: null,
                schedule: null,
                createdBy: '',
                createdAt: info.joinedAt ?? DateTime.now(),
                updatedAt: info.joinedAt ?? DateTime.now(),
                memberCount: 0,
                khademCount: 0,
                makhdoumCount: 0,
                memberships: null,
              ),
            )
            .toList(),
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

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  void _onDateSelected(String dateIso) {
    if (_currentUser?.id == null) return;
    // Only fetch if date actually changed
    if (_currentSelectedDate != dateIso) {
      _currentSelectedDate = dateIso;
      // Fetch aftekad data for selected date
      _aftekadCubit.getAftekad(
        dateIso,
        khademId: _selectedKhademId,
        classId: _selectedClassId,
      );
    }
  }

  Future<void> _refreshAftekad() {
    final selectedDate = _currentSelectedDate;
    if (selectedDate == null) return Future.value();
    return _aftekadCubit.getAftekad(
      selectedDate,
      khademId: _selectedKhademId,
      classId: _selectedClassId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aftekadCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: BlocBuilder<GetAftekadCubit, GetAftekadState>(
            builder: (context, state) {
              _AftekadViewData? viewData;
              if (state is GetAftekadSuccess) {
                viewData = _prepareAftekadViewData(state);
              }
              return RefreshIndicator(
                onRefresh: _refreshAftekad,
                color: AppColors.primaryMaroon,
                child: CustomScrollView(
                  controller: _effectiveScrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildCompactHeader(state, viewData),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: _buildAftekadSliver(state, viewData),
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

  /// Compact header for Aftekad
  Widget _buildCompactHeader(
    GetAftekadState state,
    _AftekadViewData? viewData,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon
                      .withValues(alpha: 0.1.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_search,
                  color: AppColors.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سجل الافتقاد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_currentSelectedDate != null)
                      Text(
                        DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(_currentSelectedDate!)),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showDatePicker(context);
                },
                icon: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryMaroon,
                ),
                tooltip: 'اختر تاريخ',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 12),
          if (_isLoadingClasses) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
          ],
          _buildFilterRow(),
          const SizedBox(height: 8),
          _buildAssignmentsButton(),
          if (viewData != null) ...[
            const SizedBox(height: 12),
            _buildAftekadSummary(viewData),
          ],
        ],
      ),
    );
  }

  bool get _canFilterByClass {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role == UserRole.superAdmin) {
      return _classOptions.isNotEmpty;
    }
    if (user.role == UserRole.khadem) {
      return _classOptions.length > 1;
    }
    return false;
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
      ),
    );
  }

  Widget _buildFilterRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final showKhademFilter = _shouldShowKhademFilter;
        final showClassFilter = _canFilterByClass;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showKhademFilter) ...[
                _buildKhademFilterDropdown(),
                const SizedBox(height: 12),
              ],
              if (showClassFilter) ...[
                _buildClassFilterDropdown(),
                const SizedBox(height: 12),
              ],
              _buildSortDropdown(),
              const SizedBox(height: 12),
              _buildSortDirectionButton(isFullWidth: true),
            ],
          );
        }

        final rowChildren = <Widget>[];

        if (showKhademFilter) {
          rowChildren.add(Expanded(child: _buildKhademFilterDropdown()));
        }

        if (showClassFilter) {
          if (rowChildren.isNotEmpty) {
            rowChildren.add(const SizedBox(width: 8));
          }
          rowChildren.add(Expanded(child: _buildClassFilterDropdown()));
        }

        if (rowChildren.isNotEmpty) {
          rowChildren.add(const SizedBox(width: 8));
        }
        rowChildren.add(Expanded(child: _buildSortDropdown()));
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(_buildSortDirectionButton(isFullWidth: false));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
      },
    );
  }

  Widget _buildClassFilterDropdown() {
    final options = _classOptions;
    if (options.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String?>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'اختر الفصل',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('كل الفصول'),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String?>(
            value: option.classId,
            child: Text(option.className ?? 'فصل بدون اسم'),
          ),
        ),
      ],
      onChanged: _isLoadingAssignments ? null : _onClassSelectionChanged,
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<AftekadSortOption>(
      value: _selectedSortOption,
      decoration: const InputDecoration(
        labelText: 'ترتيب حسب',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: AftekadSortOption.values
          .map(
            (option) => DropdownMenuItem<AftekadSortOption>(
              value: option,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedSortOption = value;
        });
      },
    );
  }

  Widget _buildSortDirectionButton({required bool isFullWidth}) {
    return SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          setState(() {
            _isSortDescending = !_isSortDescending;
          });
        },
        child: Icon(
          _isSortDescending ? Icons.arrow_downward : Icons.arrow_upward,
          color: AppColors.primaryMaroon,
        ),
      ),
    );
  }

  _AftekadViewData _prepareAftekadViewData(GetAftekadSuccess state) {
    final allMembers = sl<IMembersRepository>()
        .members
        .where((member) => member.role == UserRole.makhdoum)
        .toList();

    final allowedMakhdoumIds = _deriveAllowedMakhdoumIds(state);
    final filteredMembers = _filterMembersByClass(
      allMembers,
      allowedMakhdoumIds: allowedMakhdoumIds,
    );

    final completedAftekad =
        state.aftekad.where((aftekad) => aftekad.status == true).toList();
    final makhdoumsMissedFridays = state.makhdoumsMissedFridays ?? {};

    final displayList = _buildAftekadDisplayList(
      filteredMembers,
      completedAftekad,
      makhdoumsMissedFridays,
    );

    final completedCount =
        displayList.where((entry) => entry.status == true).length;
    final pendingCount = displayList.length - completedCount;
    final atRiskCount = displayList
        .where((entry) => (entry.consecutiveMissedFridays ?? 0) >= 3)
        .length;

    return _AftekadViewData(
      displayList: displayList,
      completedCount: completedCount,
      pendingCount: pendingCount,
      atRiskCount: atRiskCount,
    );
  }

  List<AftekadModel> _buildAftekadDisplayList(
    List<UserModel> members,
    List<AftekadModel> completed,
    Map<String, int> missedFridays,
  ) {
    final list = members.map((member) {
      final existing = completed.firstWhere(
        (aftekad) => aftekad.makhdoum?.id == member.id,
        orElse: () {
          final missed = missedFridays[member.id] ?? 0;
          return AftekadModel(
            makhdoumId: member.id,
            status: false,
            classId: member.classId,
            consecutiveMissedFridays: missed,
            makhdoum: Makhdoum(
              id: member.id,
              name: member.name,
            ),
          );
        },
      );

      if (existing.consecutiveMissedFridays == null &&
          missedFridays.containsKey(member.id)) {
        existing.consecutiveMissedFridays = missedFridays[member.id];
      }

      return existing;
    }).toList();

    list.sort(_compareAftekads);
    return list;
  }

  Widget _buildAftekadSummary(_AftekadViewData data) {
    final total = data.displayList.length;
    final completed = data.completedCount;
    final pending = data.pendingCount;
    final atRisk = data.atRiskCount;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryTile(
          icon: Icons.people_alt,
          label: 'إجمالي المخدومين',
          value: total.toString(),
        ),
        _buildSummaryTile(
          icon: Icons.check_circle,
          label: 'تم الافتقاد',
          value: completed.toString(),
        ),
        _buildSummaryTile(
          icon: Icons.schedule,
          label: 'قيد المتابعة',
          value: pending.toString(),
        ),
        _buildSummaryTile(
          icon: Icons.priority_high,
          label: 'بحاجة لزيارة عاجلة',
          value: atRisk.toString(),
          accentColor: Colors.orange.shade600,
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primaryMaroon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
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

  Widget _buildAftekadSliver(
    GetAftekadState state,
    _AftekadViewData? viewData,
  ) {
    if (state is GetAftekadLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      );
    }

    if (state is GetAftekadFailure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildAftekadErrorState(state.errorMessage),
      );
    }

    if (state is GetAftekadSuccess) {
      final data = viewData!;
      if (data.displayList.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildAftekadEmptyState(),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = data.displayList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AftekadListTile(aftekad: item),
            );
          },
          childCount: data.displayList.length,
        ),
      );
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: _buildSelectDateState(),
    );
  }

  Widget _buildAftekadErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ',
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

  Widget _buildAftekadEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline,
          size: 60,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 16),
        const Text(
          'لا يوجد أعضاء',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'لا يوجد أعضاء لعرض الافتقاد حاليًا.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectDateState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today,
          size: 60,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 16),
        const Text(
          'اختر جمعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر جمعة لعرض سجل الافتقاد.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<UserModel> _filterMembersByClass(
    List<UserModel> members, {
    Set<String>? allowedMakhdoumIds,
  }) {
    Iterable<UserModel> filtered = members;

    if (_selectedClassId != null) {
      filtered = filtered.where((member) {
        if (member.classes.isNotEmpty) {
          return member.classes.any((info) => info.classId == _selectedClassId);
        }
        return member.classId == _selectedClassId;
      });
    }

    if (allowedMakhdoumIds != null) {
      if (allowedMakhdoumIds.isEmpty) {
        return <UserModel>[];
      }
      filtered = filtered.where((member) {
        final id = member.id;
        if (id == null || id.isEmpty) return false;
        return allowedMakhdoumIds.contains(id);
      });
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final name = member.name?.toLowerCase() ?? '';
        return name.contains(_searchQuery);
      });
    }

    return filtered.toList();
  }

  Set<String>? _deriveAllowedMakhdoumIds(GetAftekadSuccess state) {
    final selectedKhadem = _selectedKhademId;
    if (selectedKhadem == null) {
      return null;
    }

    final ids = <String>{};

    for (final aftekad in state.aftekad) {
      final id = aftekad.makhdoum?.id ?? aftekad.makhdoumId;
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }

    final missedEntries =
        state.makhdoumsMissedFridays?.keys ?? const <String>{};
    for (final id in missedEntries) {
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }

    final assignments = _currentAssignments;
    if (assignments != null &&
        (_selectedClassId == null || assignments.classId == _selectedClassId)) {
      final assignedMakhdoums =
          assignments.groupedAssignments[selectedKhadem] ??
              const <AssignedMakhdoum>[];
      for (final entry in assignedMakhdoums) {
        if (entry.id.isNotEmpty) {
          ids.add(entry.id);
        }
      }
    }

    return ids;
  }

  int _compareAftekads(AftekadModel a, AftekadModel b) {
    int result;
    switch (_selectedSortOption) {
      case AftekadSortOption.consecutiveMissed:
        result = (b.consecutiveMissedFridays ?? 0) -
            (a.consecutiveMissedFridays ?? 0);
        if (result != 0) {
          return _isSortDescending ? result : -result;
        }
        result =
            (b.fridayAttendanceCount ?? 0) - (a.fridayAttendanceCount ?? 0);
        if (result != 0) {
          return _isSortDescending ? result : -result;
        }
        result = _compareByName(a, b);
        break;
      case AftekadSortOption.attendance:
        result =
            (b.fridayAttendanceCount ?? 0) - (a.fridayAttendanceCount ?? 0);
        if (result != 0) {
          return _isSortDescending ? result : -result;
        }
        result = (b.consecutiveMissedFridays ?? 0) -
            (a.consecutiveMissedFridays ?? 0);
        if (result != 0) {
          return _isSortDescending ? result : -result;
        }
        result = _compareByName(a, b);
        break;
      case AftekadSortOption.nameAZ:
        result = _compareByName(a, b);
        break;
    }
    return _isSortDescending ? result : -result;
  }

  int _compareByName(AftekadModel a, AftekadModel b) {
    final nameA = (a.makhdoum?.name ?? '').toLowerCase();
    final nameB = (b.makhdoum?.name ?? '').toLowerCase();
    return nameA.compareTo(nameB);
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'اختر جمعة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _fridayDates.length,
                itemBuilder: (context, index) {
                  final date = _fridayDates[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                  final isSelected = dateStr == _currentSelectedDate;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryMaroon
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _currentSelectedDate = dateStr;
                        });
                        _onDateSelected(dateStr);
                        Navigator.pop(modalContext);
                      },
                      leading: Icon(
                        Icons.calendar_today,
                        color: isSelected
                            ? AppColors.accentWhite
                            : AppColors.primaryMaroon,
                      ),
                      title: Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accentWhite
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.accentWhite,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AftekadViewData {
  _AftekadViewData({
    required this.displayList,
    required this.completedCount,
    required this.pendingCount,
    required this.atRiskCount,
  });

  final List<AftekadModel> displayList;
  final int completedCount;
  final int pendingCount;
  final int atRiskCount;
}

enum AftekadSortOption {
  consecutiveMissed,
  attendance,
  nameAZ,
}

extension AftekadSortOptionLabel on AftekadSortOption {
  String get label {
    switch (this) {
      case AftekadSortOption.consecutiveMissed:
        return 'أكثر غيابًا متتاليًا';
      case AftekadSortOption.attendance:
        return 'أعلى حضور قداسات';
      case AftekadSortOption.nameAZ:
        return 'الاسم (أ-ي)';
    }
  }
}
