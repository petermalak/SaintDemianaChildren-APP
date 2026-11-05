import 'package:flutter/material.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/utils/role_helper.dart';
import 'package:saint_demiana_children/core/widgets/class_export_selection_dialog.dart';
import 'package:saint_demiana_children/core/widgets/custom_text_field.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

class RequestMemberDialog extends StatefulWidget {
  const RequestMemberDialog({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<RequestMemberDialog> createState() => _RequestMemberDialogState();
}

class _RequestMemberDialogState extends State<RequestMemberDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _classId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final classes = RoleHelper.getKhademClasses(sl<IProfileRepository>().user)
        .where((info) => !(info.className ?? '').contains('المسرح'))
        .toList();
    if (classes.length == 1) _classId = classes.first.classId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<UserClassInfo> get _classes =>
      RoleHelper.getKhademClasses(sl<IProfileRepository>().user)
          .where((info) => !(info.className ?? '').contains('المسرح'))
          .toList();

  Future<void> _submit({String? matchedUserId, bool confirmNewPerson = false}) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.length < 2 || phone.isEmpty || _classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب الاسم والهاتف واختر الفصل')),
      );
      return;
    }
    setState(() => _sending = true);
    final result = await sl<IMembersRepository>().submitMemberRequest({
      'name': name,
      'phoneNumber': phone,
      'classId': _classId,
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (matchedUserId != null) 'matchedUserId': matchedUserId,
      if (confirmNewPerson) 'confirmNewPerson': true,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (_) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الطلب للموافقة')),
        );
      },
    );
  }

  Future<void> _checkThenSubmit() async {
    final lookup = await sl<IMembersRepository>().findDuplicates(
      phoneNumber: _phoneController.text.trim(),
      name: _nameController.text.trim(),
    );
    final data = lookup.fold<Map<String, dynamic>?>((_) => null, (value) => value);
    final phones = (data?['phoneMatches'] as List?) ?? const [];
    final names = (data?['nameHints'] as List?) ?? const [];
    if (!mounted || (phones.isEmpty && names.isEmpty)) {
      await _submit(confirmNewPerson: true);
      return;
    }
    final people = <Map<String, dynamic>>[
      ...phones.whereType<Map>().map((row) => Map<String, dynamic>.from(row)),
      ...names.whereType<Map>().map((row) => Map<String, dynamic>.from(row)),
    ];
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حساب مشابه موجود'),
        content: SingleChildScrollView(
          child: Column(
            children: people
                .map((person) => ListTile(
                      title: Text(person['name']?.toString() ?? ''),
                      subtitle: Text(person['phoneNumber']?.toString() ?? ''),
                      onTap: () => Navigator.pop(dialogContext, 'user:${person['id']}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'new'),
            child: const Text('شخص آخر'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice == 'new') {
      await _submit(confirmNewPerson: true);
    } else {
      await _submit(matchedUserId: choice.substring('user:'.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = _classes;
    final selected = classes.where((info) => info.classId == _classId).toList();
    return AlertDialog(
      title: const Text('طلب إضافة عضو'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            CustomTextField(controller: _nameController, labelText: 'الاسم'),
            const SizedBox(height: 12),
            CustomTextField(controller: _phoneController, labelText: 'الهاتف'),
            const SizedBox(height: 12),
            CustomTextField(controller: _emailController, labelText: 'الايميل (اختياري)'),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الفصل'),
              subtitle: Text(selected.isEmpty ? 'اختر فصلاً' : (selected.first.className ?? '')),
              trailing: const Icon(Icons.class_),
              onTap: classes.length <= 1
                  ? null
                  : () async {
                      final ids = await showDialog<List<String>>(
                        context: context,
                        builder: (context) => ClassExportSelectionDialog(
                          availableClasses: classes
                              .map((info) => ClassOption(
                                    id: info.classId,
                                    name: info.className ?? info.classId,
                                  ))
                              .toList(),
                          title: 'اختر فصلاً',
                          allowMultiple: false,
                        ),
                      );
                      if (ids != null && ids.isNotEmpty) {
                        setState(() => _classId = ids.first);
                      }
                    },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
          onPressed: _sending ? null : _checkThenSubmit,
          child: Text(_sending ? '...' : 'إرسال للموافقة', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
