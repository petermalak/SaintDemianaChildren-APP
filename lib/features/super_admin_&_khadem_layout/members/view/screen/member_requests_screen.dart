import 'package:flutter/material.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/repository/i_members_repository.dart';

class MemberRequestsScreen extends StatefulWidget {
  const MemberRequestsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<MemberRequestsScreen> createState() => _MemberRequestsScreenState();
}

class _MemberRequestsScreenState extends State<MemberRequestsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  bool get _isAdmin =>
      sl<IProfileRepository>().user?.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<IMembersRepository>().fetchMemberRequests(
      status: _isAdmin ? 'pending' : null,
    );
    if (!mounted) return;
    result.fold(
      (error) => setState(() {
        _loading = false;
        _error = error;
      }),
      (rows) => setState(() {
        _loading = false;
        _rows = rows;
      }),
    );
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final result = await sl<IMembersRepository>().approveMemberRequest(row['id'].toString());
    if (!mounted) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (approved) {
        final password = approved['temporaryPassword']?.toString();
        final message = password == null || password.isEmpty
            ? 'تمت الموافقة'
            : 'تمت الموافقة. الرقم السري المؤقت: $password';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        _load();
      },
    );
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'اكتب السبب')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    final result = await sl<IMembersRepository>().rejectMemberRequest(row['id'].toString(), reason);
    if (!mounted) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_rows.isEmpty) {
      return const Center(child: Text('لا توجد طلبات'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final status = row['status']?.toString() ?? '';
          return Card(
            child: ListTile(
              title: Text(row['name']?.toString() ?? ''),
              subtitle: Text(
                '${row['phoneNumber'] ?? ''} · ${row['className'] ?? ''}\n'
                '${row['requesterName'] ?? ''} · $status',
              ),
              isThreeLine: true,
              trailing: _isAdmin && status == 'pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _approve(row),
                          icon: const Icon(Icons.check, color: AppColors.primaryMaroon),
                        ),
                        IconButton(
                          onPressed: () => _reject(row),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
