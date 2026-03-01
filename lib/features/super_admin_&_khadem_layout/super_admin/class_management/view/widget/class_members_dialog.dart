import 'package:flutter/material.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/di/service_locator.dart';
import '../../model/class_members_response.dart';
import '../../model/class_membership_model.dart';
import '../../repository/i_class_repository.dart';
import 'add_class_member_dialog.dart';

/// Dialog for viewing and (for super_admin only) managing class members:
/// add user (makhdoum/khadem) to class, remove user from class.
class ClassMembersDialog extends StatefulWidget {
  const ClassMembersDialog({
    super.key,
    required this.classId,
    required this.className,
    required this.isSuperAdmin,
    this.onMembersUpdated,
  });

  final String classId;
  final String className;
  final bool isSuperAdmin;
  final VoidCallback? onMembersUpdated;

  @override
  State<ClassMembersDialog> createState() => _ClassMembersDialogState();
}

class _ClassMembersDialogState extends State<ClassMembersDialog> {
  final IClassRepository _classRepo = sl<IClassRepository>();
  final IMembersRepository _membersRepo = sl<IMembersRepository>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  ClassMembersResponse? _data;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _roleFilter; // null = all, 'khadem', 'makhdoum'

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ClassMembershipModel> get _filteredMemberships {
    if (_data == null) return [];
    var list = _data!.memberships;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((m) {
        final user = m.user;
        if (user == null) return false;
        final name = (user.name ?? '').toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        final phone = (user.phoneNumber ?? '').toLowerCase();
        final roleLabel = (m.roleDisplayName).toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            roleLabel.contains(q);
      }).toList();
    }
    if (_roleFilter != null) {
      list = list.where((m) => m.role.name == _roleFilter).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _classRepo.getClassMembers(widget.classId);
    result.fold(
      (err) => setState(() {
        _loading = false;
        _error = err;
      }),
      (data) => setState(() {
        _loading = false;
        _data = data;
        _error = null;
      }),
    );
  }

  Future<void> _addMember() async {
    final membersResult = await _membersRepo.fetchMembers(true);
    final users = membersResult.fold((_) => <UserModel>[], (list) => list);
    final existingIds = <String>{
      for (final m in _data?.memberships ?? []) m.userId,
    };

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddClassMemberDialog(
        className: widget.className,
        existingMemberIds: existingIds,
        availableUsers: users,
        onAdd: (userId, role, {notes}) async {
          final result = await _classRepo.addClassMember(
            widget.classId,
            userId,
            role,
            notes: notes,
          );
          result.fold(
            (e) => throw Exception(e),
            (_) {},
          );
        },
      ),
    );
    if (added == true) {
      await _loadMembers();
      widget.onMembersUpdated?.call();
    }
  }

  Future<void> _removeMember(ClassMembershipModel membership) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة عضو من الفصل'),
        content: Text(
          'هل أنت متأكد من إزالة ${membership.user?.name ?? 'هذا العضو'} من "${widget.className}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.accentWhite,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result =
        await _classRepo.removeUserFromClass(widget.classId, membership.userId);
    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إزالة العضو من الفصل'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadMembers();
        widget.onMembersUpdated?.call();
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return AppColors.accentGold;
      case UserRole.makhdoum:
        return AppColors.primaryBrown;
      case UserRole.superAdmin:
        return AppColors.primaryBlue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.khadem:
        return Icons.person;
      case UserRole.makhdoum:
        return Icons.child_care;
      case UserRole.superAdmin:
        return Icons.supervisor_account;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMemberships;
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_alt, color: AppColors.primaryMaroon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أعضاء ${widget.className}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_data != null && !_loading)
                  Text(
                    '${filtered.length} من ${_data!.totalMembers}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 460,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.8)),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadMembers,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('إعادة المحاولة'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                            foregroundColor: AppColors.accentWhite,
                          ),
                        ),
                      ],
                    ),
                  )
                : (_data!.memberships.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد أعضاء في هذا الفصل',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.isSuperAdmin) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _addMember,
                                icon: const Icon(Icons.person_add, size: 20),
                                label: const Text('إضافة عضو'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryMaroon,
                                  foregroundColor: AppColors.accentWhite,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.isSuperAdmin)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FilledButton.icon(
                                onPressed: _addMember,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryMaroon,
                                  foregroundColor: AppColors.accentWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.person_add, size: 20),
                                label: const Text('إضافة عضو إلى الفصل'),
                              ),
                            ),
                          // Search field
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'بحث بالاسم، البريد أو رقم الهاتف...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      tooltip: 'مسح',
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: AppColors.backgroundCard,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Role filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildRoleChip(null, 'الكل'),
                                const SizedBox(width: 8),
                                _buildRoleChip('khadem', 'خادم'),
                                const SizedBox(width: 8),
                                _buildRoleChip('makhdoum', 'مخدوم'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد نتائج للبحث',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _roleFilter = null;
                                            });
                                          },
                                          icon: const Icon(Icons.clear_all, size: 18),
                                          label: const Text('مسح الفلتر'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 4),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final m = filtered[index];
                                      final user = m.user;
                                      if (user == null) return const SizedBox.shrink();
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: AppColors.borderLight),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          leading: CircleAvatar(
                                            backgroundColor: _getRoleColor(user.role!).withValues(alpha: 0.2),
                                            child: Icon(
                                              _getRoleIcon(user.role!),
                                              color: _getRoleColor(user.role!),
                                              size: 22,
                                            ),
                                          ),
                                          title: Text(
                                            user.name ?? user.email ?? '—',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            '${m.roleDisplayName} • ${user.email ?? user.phoneNumber ?? ''}',
                                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: widget.isSuperAdmin
                                              ? IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                                  onPressed: () => _removeMember(m),
                                                  tooltip: 'إزالة من الفصل',
                                                )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      )),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String? value, String label) {
    final isSelected = _roleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _roleFilter = selected ? value : null),
      selectedColor: AppColors.primaryMaroon.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryMaroon,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
