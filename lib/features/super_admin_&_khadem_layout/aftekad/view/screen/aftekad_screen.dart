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

  @override
  void initState() {
    super.initState();
    _generateFridayDates();
    _aftekadCubit =
        GetAftekadCubit(sl<IAftekadRepository>(), sl<DataRefreshCubit>());

    _currentUser = sl<IProfileRepository>().user;
    _assignedClasses = (_currentUser?.classes ?? const [])
        .where((info) => info.classId.isNotEmpty)
        .toList();
    _classOptions = _assignedClasses;
    _loadClassOptions();

    _searchController.addListener(_onSearchChanged);

    // Load initial data
    if (_fridayDates.isNotEmpty && _currentUser?.id != null) {
      final mostRecentFriday = _fridayDates.first;
      final formattedDate = DateFormat('yyyy-MM-dd').format(mostRecentFriday);
      _currentSelectedDate = formattedDate;
      _aftekadCubit.getAftekad(
        formattedDate,
        _currentUser!.id!,
        classId: _selectedClassId,
      );
    }
  }

  @override
  void dispose() {
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
    if (_currentUser?.role != UserRole.khadem) return;

    setState(() {
      _isLoadingClasses = true;
    });

    final classRepository = sl<IClassRepository>();
    final result = await classRepository.loadMyClasses();

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _isLoadingClasses = false;
        });
      },
      (classList) {
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

        setState(() {
          _classOptions = combined.values.toList();
          _isLoadingClasses = false;
        });
      },
    );
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
        _currentUser!.id!,
        classId: _selectedClassId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aftekadCubit,
      child: Column(
        children: [
          _buildCompactHeader(),
          Expanded(
            child: _buildAftekadList(),
          ),
        ],
      ),
    );
  }

  /// Compact header for Aftekad
  Widget _buildCompactHeader() {
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
        ],
      ),
    );
  }

  bool get _canFilterByClass =>
      _currentUser?.role == UserRole.khadem && _classOptions.isNotEmpty;

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
    final widgets = <Widget>[];

    if (_canFilterByClass) {
      widgets.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildClassFilterDropdown(),
          ),
        ),
      );
    }

    widgets.add(
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: _canFilterByClass ? 8.0 : 0.0),
          child: _buildSortDropdown(),
        ),
      ),
    );

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: SizedBox(
          height: 48,
          width: 48,
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
        ),
      ),
    );

    return Row(
      children: widgets,
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
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
        });

        if (_currentSelectedDate != null && _currentUser?.id != null) {
          _aftekadCubit.getAftekad(
            _currentSelectedDate!,
            _currentUser!.id!,
            classId: value,
          );
        }
      },
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

  List<UserModel> _filterMembersByClass(List<UserModel> members) {
    Iterable<UserModel> filtered = members;

    if (_selectedClassId != null) {
      filtered = filtered.where((member) {
        if (member.classes.isNotEmpty) {
          return member.classes.any((info) => info.classId == _selectedClassId);
        }
        return member.classId == _selectedClassId;
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

  Widget _buildAftekadList() {
    return BlocBuilder<GetAftekadCubit, GetAftekadState>(
      builder: (context, state) {
        if (state is GetAftekadLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryMaroon,
            ),
          );
        } else if (state is GetAftekadFailure) {
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
              ],
            ),
          );
        } else if (state is GetAftekadSuccess) {
          print('📋 [AftekadScreen] Building list with GetAftekadSuccess');
          print(
              '📋 [AftekadScreen] State aftekad count: ${state.aftekad.length}');

          // Get all members from repository
          final allMembers = sl<IMembersRepository>()
              .members
              .where((member) => member.role == UserRole.makhdoum)
              .toList();

          print('📋 [AftekadScreen] All members count: ${allMembers.length}');

          final filteredMembers = _filterMembersByClass(allMembers);
          print(
              '📋 [AftekadScreen] Filtered members count: ${filteredMembers.length}');

          // Get completed aftekad data
          final completedAftekad =
              state.aftekad.where((aftekad) => aftekad.status == true).toList();

          print(
              '📋 [AftekadScreen] Completed aftekad count: ${completedAftekad.length}');

          // Get makhdoumsMissedFridays from state
          final makhdoumsMissedFridays = state.makhdoumsMissedFridays ?? {};

          // Create a combined list showing completion status for each member
          final displayList = filteredMembers.map((member) {
            // Check if this member has completed aftekad
            final memberAftekad = completedAftekad.firstWhere(
              (aftekad) => aftekad.makhdoum?.id == member.id,
              orElse: () {
                // Use consecutive missed Fridays from backend if available, otherwise 0
                final missedFridays = makhdoumsMissedFridays[member.id] ?? 0;
                return AftekadModel(
                  makhdoumId: member.id,
                  status: false,
                  classId: member.classId,
                  consecutiveMissedFridays: missedFridays,
                  makhdoum: Makhdoum(
                    id: member.id,
                    name: member.name,
                  ),
                );
              },
            );

            // If member has aftekad but consecutiveMissedFridays is not set, use from map
            if (memberAftekad.consecutiveMissedFridays == null &&
                makhdoumsMissedFridays.containsKey(member.id)) {
              memberAftekad.consecutiveMissedFridays =
                  makhdoumsMissedFridays[member.id];
            }

            return memberAftekad;
          }).toList();

          // Apply the selected sorting strategy
          displayList.sort(_compareAftekads);

          print('📋 [AftekadScreen] Display list count: ${displayList.length}');
          print(
              '📋 [AftekadScreen] Completed in display: ${displayList.where((a) => a.status == true).length}');

          if (displayList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 60,
                    color: AppColors.textSecondary,
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
                    'لا يوجد أعضاء لعرض الافتقاد',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (_currentSelectedDate != null && _currentUser?.id != null) {
                await _aftekadCubit.getAftekad(
                  _currentSelectedDate!,
                  _currentUser!.id!,
                  classId: _selectedClassId,
                );
              }
            },
            color: AppColors.primaryMaroon,
            child: ListView.separated(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) => AftekadListTile(
                aftekad: displayList[index],
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: displayList.length,
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 60,
                color: AppColors.textSecondary,
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
                'اختر جمعة لعرض سجل الافتقاد',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
