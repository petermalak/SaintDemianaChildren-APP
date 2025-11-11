import 'package:flutter/material.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_assignment_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';

class ManageAssignmentsDialog extends StatefulWidget {
  final List<ClassModel> availableClasses;
  final String? initialClassId;

  const ManageAssignmentsDialog({
    super.key,
    this.availableClasses = const [],
    this.initialClassId,
  });

  @override
  State<ManageAssignmentsDialog> createState() =>
      _ManageAssignmentsDialogState();
}

class _ManageAssignmentsDialogState extends State<ManageAssignmentsDialog> {
  late final IClassRepository _classRepository = sl<IClassRepository>();
  late final IProfileRepository _profileRepository = sl<IProfileRepository>();

  List<ClassModel> _classes = const [];
  String? _selectedClassId;
  ClassAssignmentsModel? _assignments;
  String? _activeKhademId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  final Map<String, Set<String>> _selections = {};
  final Map<String, Map<String, String?>> _notes = {};

  @override
  void initState() {
    super.initState();
    _classes = widget.availableClasses;
    _selectedClassId = widget.initialClassId ??
        (widget.availableClasses.isNotEmpty
            ? widget.availableClasses.first.id
            : null);

    if (_classes.isEmpty) {
      _loadClasses();
    } else if (_selectedClassId != null) {
      _loadAssignments(_selectedClassId!);
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = _profileRepository.user;
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;
    final result = isSuperAdmin
        ? await _classRepository.loadClasses()
        : await _classRepository.loadMyClasses();

    result.fold(
      (error) {
        setState(() {
          _classes = const [];
          _errorMessage = error;
          _isLoading = false;
        });
      },
      (classes) {
        setState(() {
          _classes = classes;
          if (classes.isNotEmpty) {
            _selectedClassId ??= classes.first.id;
          }
          _isLoading = false;
        });

        if (_selectedClassId != null) {
          _loadAssignments(_selectedClassId!);
        }
      },
    );
  }

  Future<void> _loadAssignments(String classId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _assignments = null;
    });

    final result = await _classRepository.loadClassAssignments(classId);
    result.fold(
      (error) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      },
      (assignments) {
        final selections = <String, Set<String>>{};
        for (final khadem in assignments.khadems) {
          final assigned =
              assignments.groupedAssignments[khadem.id] ?? const [];
          selections[khadem.id] = assigned
              .map((entry) => entry.id)
              .where((id) => id.isNotEmpty)
              .toSet();
        }

        setState(() {
          _assignments = assignments;
          _selections
            ..clear()
            ..addAll(selections);
          _activeKhademId = assignments.khadems.isNotEmpty
              ? assignments.khadems.first.id
              : null;
          _isLoading = false;
        });
      },
    );
  }

  List<AssignmentUser> _buildMakhdoumList(ClassAssignmentsModel assignments) {
    final map = <String, AssignmentUser>{};
    for (final user in assignments.makhdoums) {
      if (user.id.isNotEmpty) {
        map[user.id] = user;
      }
    }
    for (final user in assignments.unassignedMakhdoums) {
      if (user.id.isNotEmpty) {
        map.putIfAbsent(user.id, () => user);
      }
    }
    for (final entries in assignments.groupedAssignments.values) {
      for (final assigned in entries) {
        if (assigned.id.isNotEmpty) {
          map.putIfAbsent(
            assigned.id,
            () => AssignmentUser(
              id: assigned.id,
              name: assigned.name,
              email: assigned.email,
              phoneNumber: assigned.phoneNumber,
              role: 'makhdoum',
            ),
          );
        }
      }
    }

    final list = map.values.toList();
    list.sort(
      (a, b) => (a.name ?? a.id).compareTo(b.name ?? b.id),
    );
    return list;
  }

  String? _findAssignedKhademId(String makhdoumId) {
    for (final entry in _selections.entries) {
      if (entry.value.contains(makhdoumId)) {
        return entry.key;
      }
    }
    return null;
  }

  void _toggleMakhdoumSelection(
      String khademId, String makhdoumId, bool value) {
    final currentSet = _selections.putIfAbsent(khademId, () => <String>{});
    if (value) {
      for (final entry in _selections.entries) {
        if (entry.key != khademId && entry.value.remove(makhdoumId)) {
          // Ensure removal from other khadem assignments for exclusivity
        }
      }
      currentSet.add(makhdoumId);
    } else {
      currentSet.remove(makhdoumId);
    }
    setState(() {});
  }

  Future<void> _saveAssignments() async {
    final classId = _selectedClassId;
    if (classId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await _classRepository.updateClassAssignments(
      classId,
      _selections,
      notes: _notes.isEmpty ? null : _notes,
    );

    result.fold(
      (error) {
        setState(() {
          _errorMessage = error;
          _isSaving = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (assignments) {
        setState(() {
          _assignments = assignments;
          _selections
            ..clear()
            ..addAll({
              for (final khadem in assignments.khadems)
                khadem.id:
                    (assignments.groupedAssignments[khadem.id] ?? const [])
                        .map((entry) => entry.id)
                        .where((id) => id.isNotEmpty)
                        .toSet(),
            });
          _isSaving = false;
        });

        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClassDropdown(),
        const SizedBox(height: 16),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        if (_isLoading)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_assignments == null)
          const SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'اختر فصلاً لعرض التوزيعات',
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        else
          _buildAssignmentsContent(_assignments!),
      ],
    );

    return AlertDialog(
      title: const Text('إدارة توزيع المخدومين'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: content,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAssignments,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  Widget _buildClassDropdown() {
    final options = _classes;
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'اختر الفصل',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: options
          .map(
            (classModel) => DropdownMenuItem<String>(
              value: classModel.id,
              child: Text(classModel.name),
            ),
          )
          .toList(),
      onChanged: _isLoading || _isSaving
          ? null
          : (value) {
              if (value == null || value == _selectedClassId) return;
              setState(() {
                _selectedClassId = value;
                _assignments = null;
              });
              _loadAssignments(value);
            },
    );
  }

  Widget _buildAssignmentsContent(ClassAssignmentsModel assignments) {
    final khadems = assignments.khadems;
    final makhdoums = _buildMakhdoumList(assignments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (khadems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا يوجد خدام مرتبطون بهذا الفصل حالياً.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: khadems
                .map(
                  (khadem) => ChoiceChip(
                    label: Text(khadem.name ?? 'خادم بدون اسم'),
                    selectedColor:
                        AppColors.primaryMaroon.withValues(alpha: 0.2),
                    selected: _activeKhademId == khadem.id,
                    onSelected: (value) {
                      if (!value) return;
                      setState(() {
                        _activeKhademId = khadem.id;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 16),
        if (_activeKhademId == null)
          const Text(
            'اختر خادماً لعرض المخدومين المرتبطين به.',
            style: TextStyle(fontSize: 14),
          )
        else if (makhdoums.isEmpty)
          const Text(
            'لا يوجد مخدومون في هذا الفصل.',
            style: TextStyle(fontSize: 14),
          )
        else ...[
          for (var index = 0; index < makhdoums.length; index++) ...[
            CheckboxListTile(
              value:
                  _selections[_activeKhademId]?.contains(makhdoums[index].id) ??
                      false,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                makhdoums[index].name?.isNotEmpty == true
                    ? makhdoums[index].name!
                    : 'مخدوم بدون اسم',
              ),
              subtitle: () {
                final assignedKhademId =
                    _findAssignedKhademId(makhdoums[index].id);
                if (assignedKhademId != null &&
                    assignedKhademId != _activeKhademId) {
                  return Text(
                    'مُسند إلى خادم آخر',
                    style: TextStyle(
                      color: AppColors.primaryMaroon.withValues(
                        alpha: 0.7.clamp(0.0, 1.0),
                      ),
                    ),
                  );
                }
                return null;
              }(),
              onChanged: (value) {
                if (value == null) return;
                _toggleMakhdoumSelection(
                  _activeKhademId!,
                  makhdoums[index].id,
                  value,
                );
              },
            ),
            if (index != makhdoums.length - 1) const Divider(height: 1),
          ],
        ],
      ],
    );
  }
}
