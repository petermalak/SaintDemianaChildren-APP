import 'package:flutter/material.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Dialog for super_admin to add a user (makhdoum or khadem) to a class.
/// [existingMemberIds] should be the set of user IDs already in the class.
class AddClassMemberDialog extends StatefulWidget {
  const AddClassMemberDialog({
    super.key,
    required this.className,
    required this.existingMemberIds,
    required this.availableUsers,
    required this.onAdd,
  });

  final String className;
  final Set<String> existingMemberIds;
  final List<UserModel> availableUsers;
  final Future<void> Function(String userId, String role, {String? notes})
      onAdd;

  @override
  State<AddClassMemberDialog> createState() => _AddClassMemberDialogState();
}

class _AddClassMemberDialogState extends State<AddClassMemberDialog> {
  final TextEditingController _searchController = TextEditingController();

  UserModel? _selectedUser;
  UserRole _selectedRole = UserRole.makhdoum;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<UserModel> get _availableUsers => widget.availableUsers
      .where((u) => u.id != null && !widget.existingMemberIds.contains(u.id))
      .toList();

  List<UserModel> get _searchFilteredUsers {
    final list = _availableUsers;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((u) {
      final name = (u.name ?? '').toLowerCase();
      final email = (u.email ?? '').toLowerCase();
      final phone = (u.phoneNumber ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedUser?.id == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final roleStr = _selectedRole == UserRole.khadem ? 'khadem' : 'makhdoum';
      await widget.onAdd(_selectedUser!.id!, roleStr);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _availableUsers;
    final filtered = _searchFilteredUsers;
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add,
                color: AppColors.primaryMaroon, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'إضافة عضو إلى ${widget.className}',
              style: const TextStyle(fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: users.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text(
                      'جميع المستخدمين مضافون بالفعل إلى هذا الفصل، أو لا يوجد مستخدمون.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم، البريد أو رقم الهاتف...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.primaryMaroon),
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
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? '${filtered.length} مستخدم متاح'
                        : '${filtered.length} نتيجة',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  // Role selector chips
                  const Text(
                    'الدور في الفصل',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildRoleChip(UserRole.makhdoum, 'مخدوم'),
                      const SizedBox(width: 8),
                      _buildRoleChip(UserRole.khadem, 'خادم'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Selected user chip
                  if (_selectedUser != null) ...[
                    Card(
                      elevation: 0,
                      color: AppColors.primaryMaroon.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color:
                                AppColors.primaryMaroon.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryMaroon
                                  .withValues(alpha: 0.2),
                              child: Text(
                                _firstChar(_selectedUser!.name ??
                                    _selectedUser!.email ??
                                    '?'),
                                style: const TextStyle(
                                  color: AppColors.primaryMaroon,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedUser!.name ??
                                        _selectedUser!.email ??
                                        '—',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (_selectedUser!.email != null &&
                                      _selectedUser!.email!.isNotEmpty)
                                    Text(
                                      _selectedUser!.email!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  setState(() => _selectedUser = null),
                              tooltip: 'إلغاء الاختيار',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'اختر المستخدم',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 40,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                Text(
                                  'لا توجد نتائج للبحث',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              final isSelected = _selectedUser?.id == u.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryMaroon
                                        : AppColors.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primaryMaroon
                                            .withValues(alpha: 0.2)
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.1),
                                    child: Text(
                                      _firstChar(u.name ?? u.email ?? '?'),
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primaryMaroon
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    u.name ?? u.email ?? '—',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: (u.email != null &&
                                              u.email!.isNotEmpty) ||
                                          (u.phoneNumber != null &&
                                              u.phoneNumber!.isNotEmpty)
                                      ? Text(
                                          u.email ?? u.phoneNumber ?? '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.primaryMaroon,
                                          size: 22)
                                      : null,
                                  onTap: _isSubmitting
                                      ? null
                                      : () => setState(() => _selectedUser = u),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        if (users.isNotEmpty)
          FilledButton(
            onPressed: _isSubmitting || _selectedUser == null ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: AppColors.accentWhite,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accentWhite),
                  )
                : const Text('إضافة'),
          ),
      ],
    );
  }

  String _firstChar(String s) {
    if (s.isEmpty) return '?';
    return s.substring(0, 1).toUpperCase();
  }

  Widget _buildRoleChip(UserRole role, String label) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: _isSubmitting
          ? null
          : (selected) => setState(() => _selectedRole = role),
      selectedColor: AppColors.primaryMaroon.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryMaroon,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }
}
