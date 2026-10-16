import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../model/attendance_models.dart';
import '../../repository/i_pope_attendance_repository.dart';

class PopeLevelTwoBoardScreen extends StatefulWidget {
  const PopeLevelTwoBoardScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<PopeLevelTwoBoardScreen> createState() => _PopeLevelTwoBoardScreenState();
}

class _PopeLevelTwoBoardScreenState extends State<PopeLevelTwoBoardScreen> {
  late DateTime _date;
  String _filter = 'all';
  String _search = '';
  LevelTwoBoard? _board;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _load();
  }

  String get _iso {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '${_date.year}-$month-$day';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<IPopeAttendanceRepository>().levelTwoBoard(_iso);
    if (!mounted) return;
    result.fold(
      (message) => setState(() {
        _loading = false;
        _error = message;
      }),
      (board) => setState(() {
        _loading = false;
        _board = board;
      }),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final people = (_board?.people ?? []).where((person) {
      if (_filter == 'missing-bible' && person.bible) return false;
      if (_filter == 'missing-doctrine' && person.doctrine) return false;
      if (_filter == 'missing-either' && person.bible && person.doctrine) return false;
      final needle = _search.trim();
      if (needle.isEmpty) return true;
      return person.name.contains(needle) || person.phoneNumber.contains(needle);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('حضور الفرقة الثانية'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_iso),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('الكل', 'all'),
                _chip('بدون كتاب', 'missing-bible'),
                _chip('بدون عقيدة', 'missing-doctrine'),
                _chip('ناقص اجتماع', 'missing-either'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'الاسم أو الهاتف',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          if (_board != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _count('الفرقة', _board!.total),
                  _count('كتاب المقدس', _board!.biblePresent),
                  _count('عقيدة', _board!.doctrinePresent),
                ],
              ),
            ),
          Expanded(child: _body(people)),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        selectedColor: AppColors.primaryMaroon,
        labelStyle: TextStyle(
          color: _filter == value ? AppColors.accentWhite : AppColors.textPrimary,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _count(String label, int value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<LevelTwoPerson> people) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (people.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final person = people[index];
        return Card(
          child: ListTile(
            title: Text(person.name),
            subtitle: Text([
              if (person.group.isNotEmpty) person.group,
              if (person.phoneNumber.isNotEmpty) person.phoneNumber,
            ].join(' · ')),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _mark('كتاب', person.bible),
                const SizedBox(height: 4),
                _mark('عقيدة', person.doctrine),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mark(String label, bool present) {
    return Text(
      '$label: ${present ? 'حضور' : 'لم يُسجل'}',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: present ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }
}
