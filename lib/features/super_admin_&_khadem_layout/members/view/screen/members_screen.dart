import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/member_card.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/get_members/get_members_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/excel_export_service.dart';
import '../../../../../core/widgets/class_export_selection_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../authentication/model/user_model.dart';
import '../../repository/i_members_repository.dart';
import '../widget/manage_assignments_dialog.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({
    super.key,
    required this.cardAnimation,
    this.onSelectionChanged,
    this.scrollController,
  });
  final Animation<double> cardAnimation;
  final ValueChanged<List<UserModel>>? onSelectionChanged;
  final ScrollController? scrollController;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  /// userId -> lowercase name/email/phone, so typing does not rebuild these strings.
  final Map<String, String> _searchIndex = {};
  final List<UserModel> _selectedMembers = [];
  late GetMembersCubit _membersCubit;
  bool _isGridView = true; // true for grid, false for list
  UserModel? _currentUser;
  String? _selectedClassId;
  bool _isLoadingClasses = false;
  List<ClassModel> _availableClasses = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentUser = sl<IProfileRepository>().user;
    _membersCubit = GetMembersCubit(sl<IMembersRepository>())..getMembers();
    _loadClassesIfNeeded();
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
        print('⚠️ [MembersScreen] Failed to load classes: $error');
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

  List<UserModel> _filterMembersByClass(List<UserModel> members) {
    if (_selectedClassId == null) return members;

    return members.where((member) {
      if (member.classes.isNotEmpty) {
        return member.classes.any((info) => info.classId == _selectedClassId);
      }
      return member.classId == _selectedClassId;
    }).toList();
  }

  String _searchTextFor(UserModel member) {
    final id = member.id ?? '';
    final cached = _searchIndex[id];
    if (cached != null) return cached;
    final text = [member.name, member.email, member.phoneNumber]
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    if (id.isNotEmpty) _searchIndex[id] = text;
    return text;
  }

  List<UserModel> _applySearch(List<UserModel> members) {
    if (_searchQuery.isEmpty) return members;
    final query = _searchQuery.toLowerCase();
    return members
        .where((member) => _searchTextFor(member).contains(query))
        .toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    // Wait for a pause in typing: filtering rebuilds every visible member card.
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  bool get _canManageAssignments {
    final user = _currentUser;
    if (user == null) return false;
    return user.role == UserRole.superAdmin || user.role == UserRole.khadem;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _membersCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocProvider.value(
      value: _membersCubit,
      child: BlocBuilder<GetMembersCubit, GetMembersState>(
        builder: (context, state) {
          if (state is GetMembersLoading) {
            return const AppLoadingView(message: 'جاري تحميل الأعضاء...');
          } else if (state is GetMembersFailure) {
            return AppErrorView(
              title: 'تعذر تحميل الأعضاء',
              message: state.errorMessage,
              onRetry: () => _membersCubit.getMembers(forceRefresh: true),
            );
          } else if (state is GetMembersSuccess) {
            // Filter out current user
            final currentUser = sl<IProfileRepository>().user;
            final classMembers = _filterMembersByClass(state.members
                .where((member) => member.id != currentUser?.id)
                .toList());

            // The lists show the search results; export stays on the whole class.
            final filteredMembers = _applySearch(classMembers);

            return RefreshIndicator(
                onRefresh: () async {
                  _membersCubit.getMembers();
                },
                child: Column(
                  children: [
                    _buildSearchSection(),
                    _buildClassFilter(),
                    _buildExportButton(classMembers),
                    _buildAssignmentsButton(),
                    _buildViewToggle(),
                    Expanded(
                      child: filteredMembers.isEmpty
                          ? AppEmptyView(
                              icon: Icons.search_off,
                              title: _searchController.text.isEmpty
                                  ? 'لا يوجد أعضاء'
                                  : 'لا توجد نتائج للبحث',
                            )
                          : _isGridView
                              ? GridView.builder(
                                  controller: widget.scrollController,
                                  cacheExtent: 400,
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    mainAxisExtent: 176,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredMembers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredMembers[index];
                                    return StatefulBuilder(
                                        key: ValueKey(user.id),
                                        builder: (context, set) {
                                      return MemberCard(
                                          selectedList: _selectedMembers,
                                          user: user,
                                          isCompact: true,
                                          onUpdate: () => set(() {}),
                                          cardAnimation: widget.cardAnimation,
                                          onSelectionChanged: (isSelected) =>
                                              _selectedMembers.length > 1
                                                  ? null
                                                  : setState(() {
                                                      widget.onSelectionChanged
                                                          ?.call(
                                                              _selectedMembers);
                                                    }));
                                    });
                                  },
                                )
                              : ListView.builder(
                                  controller: widget.scrollController,
                                  cacheExtent: 400,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredMembers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredMembers[index];
                                    return StatefulBuilder(
                                        key: ValueKey(user.id),
                                        builder: (context, set) {
                                      return MemberCard(
                                          selectedList: _selectedMembers,
                                          user: user,
                                          isCompact: true,
                                          isListView: true,
                                          onUpdate: () => set(() {}),
                                          cardAnimation: widget.cardAnimation,
                                          onSelectionChanged: (isSelected) =>
                                              _selectedMembers.length > 1
                                                  ? null
                                                  : setState(() {
                                                      widget.onSelectionChanged
                                                          ?.call(
                                                              _selectedMembers);
                                                    }));
                                    });
                                  },
                                ),
                    ),
                  ],
                ));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن الأعضاء...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: AppColors.primaryMaroon
                          .withValues(alpha: 0.7.clamp(0.0, 1.0))),
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
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
        },
      ),
    );
  }

  Widget _buildAssignmentsButton() {
    if (!_canManageAssignments || _availableClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _isLoadingClasses ? null : _openManageAssignmentsDialog,
          icon: const Icon(Icons.assignment_ind),
          label: const Text('توزيع المخدومين'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: AppColors.accentWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    color: _isGridView
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = true;
                    });
                  },
                  tooltip: 'عرض الشبكة',
                ),
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: !_isGridView
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = false;
                    });
                  },
                  tooltip: 'عرض القائمة',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManageAssignmentsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ManageAssignmentsDialog(
        availableClasses: _availableClasses,
        initialClassId: _selectedClassId,
      ),
    );

    if (result == true) {
      // Reload members list to reflect any changes
      _membersCubit.getMembers();
      _loadClassesIfNeeded();
    }
  }

  /// Re-fetch members from API (so Pope Athanasius and other full profile data is included) then run export.
  /// When [classId] is set, uses GET class members (includes Pope data); otherwise uses GET users/members.
  Future<List<UserModel>?> _fetchFreshMembersForExport(
      {String? classId}) async {
    if (classId != null && classId.isNotEmpty) {
      final result = await sl<IMembersRepository>().fetchClassMembers(classId);
      return result.fold((_) => null, (list) => list);
    }
    final isSuperAdmin = _currentUser?.role == UserRole.superAdmin;
    final result = await sl<IMembersRepository>()
        .fetchMembers(isSuperAdmin, classId: classId);
    return result.fold((_) => null, (list) => list);
  }

  Widget _buildExportButton(List<UserModel> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    final hasMultipleClasses = _availableClasses.length > 1;
    final currentUser = _currentUser;
    final isKhadem = currentUser?.role == UserRole.khadem;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('جاري تحميل البيانات للتصدير...'),
              duration: Duration(seconds: 2),
            ),
          );

          if (hasMultipleClasses && isKhadem) {
            // Show class selection dialog
            final selectedClassIds = await showDialog<List<String>>(
              context: context,
              builder: (context) => ClassExportSelectionDialog(
                availableClasses: _availableClasses
                    .map((c) => ClassOption(id: c.id, name: c.name))
                    .toList(),
                title: 'اختر الفصول لتصدير الأعضاء',
              ),
            );

            if (selectedClassIds == null || selectedClassIds.isEmpty) {
              return; // User cancelled
            }

            // Re-fetch fresh members (with Pope Athanasius data) for selected class(es)
            final classIdForFetch =
                selectedClassIds.length == 1 ? selectedClassIds.first : null;
            final freshList =
                await _fetchFreshMembersForExport(classId: classIdForFetch);
            if (freshList == null) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('حدث خطأ أثناء تحميل البيانات'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            final filteredMembers = freshList
                .where((member) => member.id != currentUser?.id)
                .where((member) {
              if (selectedClassIds.length == 1) {
                final classId = selectedClassIds.first;
                if (member.classes.isNotEmpty) {
                  return member.classes.any((info) => info.classId == classId);
                }
                return member.classId == classId;
              }
              if (member.classes.isNotEmpty) {
                return member.classes
                    .any((info) => selectedClassIds.contains(info.classId));
              }
              return member.classId != null &&
                  selectedClassIds.contains(member.classId);
            }).toList();

            if (filteredMembers.isEmpty) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('لا توجد أعضاء في الفصول المحددة'),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }

            final classNamesMap = {
              for (var classModel in _availableClasses)
                classModel.id: classModel.name
            };

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                    'جاري تصدير ${filteredMembers.length} عضو من ${selectedClassIds.length} فصل...'),
                duration: const Duration(seconds: 2),
              ),
            );

            final className = selectedClassIds.length == 1
                ? classNamesMap[selectedClassIds.first]
                : 'عدة_فصول';

            final result = await ExcelExportService.exportMembers(
              filteredMembers,
              className,
              classNamesMap: selectedClassIds.length > 1 ? classNamesMap : null,
            );

            if (result != null) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: const Text('تم تصدير البيانات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: const Text('حدث خطأ أثناء التصدير'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } else {
            // Single class or super admin: re-fetch fresh members (with Pope data) then export
            final freshList =
                await _fetchFreshMembersForExport(classId: _selectedClassId);
            if (freshList == null) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('حدث خطأ أثناء تحميل البيانات'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            var membersToExport = freshList
                .where((member) => member.id != currentUser?.id)
                .toList();
            if (_selectedClassId != null) {
              membersToExport = membersToExport.where((member) {
                if (member.classes.isNotEmpty) {
                  return member.classes
                      .any((info) => info.classId == _selectedClassId);
                }
                return member.classId == _selectedClassId;
              }).toList();
            }

            final className = _selectedClassId != null
                ? _availableClasses
                    .firstWhere(
                      (c) => c.id == _selectedClassId,
                      orElse: () => ClassModel(
                        id: '',
                        name: '',
                        isActive: true,
                        createdBy: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    )
                    .name
                : null;

            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('جاري تصدير البيانات...'),
                duration: Duration(seconds: 1),
              ),
            );

            final result = await ExcelExportService.exportMembers(
              membersToExport,
              className,
            );

            if (result != null) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: const Text('تم تصدير البيانات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: const Text('حدث خطأ أثناء التصدير'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.download),
        label: Text(hasMultipleClasses && isKhadem
            ? 'تصدير إلى Excel (اختر الفصول)'
            : 'تصدير إلى Excel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: AppColors.accentWhite,
        ),
      ),
    );
  }
}
