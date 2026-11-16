import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../authentication/model/user_model.dart';
import '../repository/i_program_repository.dart';
import 'program_scanner.dart';

class ServiceAttendancePanel extends StatefulWidget {
  const ServiceAttendancePanel({
    super.key,
    required this.program,
    required this.classId,
  });

  final ProgramMembership program;
  final String classId;

  @override
  State<ServiceAttendancePanel> createState() => _ServiceAttendancePanelState();
}

class _Choice {
  const _Choice(this.id, this.label);

  final String id;
  final String label;
}

class _ServiceAttendancePanelState extends State<ServiceAttendancePanel> {
  final _programs = sl<IProgramRepository>();
  final _reason = TextEditingController();
  final _search = TextEditingController();
  List<_Choice> _types = const [];
  List<_Choice> _members = const [];
  String? _typeId;
  String? _memberId;
  String? _historyTypeId;
  String _way = 'all';
  late DateTime _from;
  late DateTime _to;
  List<Map<String, dynamic>> _history = const [];
  bool _historyLimited = false;
  String? _historyError;
  bool _busy = false;
  int _historyToken = 0;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _to = DateTime(today.year, today.month, today.day);
    _from = DateTime(today.year, today.month, 1);
    _search.addListener(_scheduleHistory);
    _load();
  }

  @override
  void didUpdateWidget(covariant ServiceAttendancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId || oldWidget.program.id != widget.program.id) {
      _memberId = null;
      _load();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.removeListener(_scheduleHistory);
    _reason.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final catalog = await _programs.catalog(widget.program.id);
    final members = await _programs.classMembers(widget.program.id, widget.classId);
    if (!mounted) return;
    setState(() {
      catalog.fold((_) {}, (data) {
        if (data is! Map) return;
        final rows = data['attendanceTypes'];
        _types = rows is List
            ? rows.whereType<Map>().where((row) => row['isActive'] != false).map((row) {
                return _Choice(row['id'].toString(), '${row['name']} · ${row['points']} نقطة');
              }).toList()
            : const [];
        _typeId = _types.any((row) => row.id == _typeId) ? _typeId : (_types.isEmpty ? null : _types.first.id);
        if (_historyTypeId != null && !_types.any((row) => row.id == _historyTypeId)) _historyTypeId = null;
      });
      members.fold((_) {}, (data) {
        final rows = data is List ? data.whereType<Map>() : const <Map>[];
        _members = rows.map((row) {
          final exempt = row['pointMinimumExempt'] == true;
          final name = (row['name'] ?? 'بدون اسم').toString();
          return _Choice(row['id'].toString(), exempt ? '$name · معفى' : name);
        }).toList();
        _memberId = _members.any((row) => row.id == _memberId) ? _memberId : null;
      });
    });
    await _loadHistory();
  }

  void _scheduleHistory() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final token = ++_historyToken;
    final result = await _programs.attendanceHistory(
      widget.program.id,
      classId: widget.classId,
      attendanceTypeId: _historyTypeId,
      from: _from,
      to: _to,
      query: _search.text,
      manual: _way == 'all' ? null : _way == 'manual',
    );
    if (!mounted || token != _historyToken) return;
    result.fold(
      (error) => setState(() => _historyError = error),
      (data) {
        final map = data is Map ? data : const {};
        final rows = map['rows'];
        setState(() {
          _historyError = null;
          _historyLimited = map['limited'] == true;
          _history = rows is List
              ? rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
              : const [];
        });
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<dynamic> request, String done) async {
    setState(() => _busy = true);
    final result = await request;
    if (!mounted) return;
    var saved = false;
    result.fold(
      (error) => _toast(error as String),
      (data) {
        saved = true;
        if (data is Map && data['queued'] == true) {
          _toast((data['message'] ?? 'اتحفظ المسح على الجهاز وهيتبعت لما النت يرجع').toString());
          return;
        }
        _toast(done);
      },
    );
    if (mounted) setState(() => _busy = false);
    if (saved) await _loadHistory();
  }

  bool _ready() {
    if (_typeId == null || _typeId!.isEmpty) {
      _toast('اختَر نوع الحضور');
      return false;
    }
    return true;
  }

  Future<void> _scan() async {
    final typeId = _typeId;
    if (!_ready() || typeId == null) return;
    final token = await showProgramScanner(context);
    if (token == null || !mounted) return;
    await _run(
      _programs.scanQr(widget.program.id, classId: widget.classId, attendanceTypeId: typeId, token: token),
      'تم المسح',
    );
  }

  void _manual() {
    final typeId = _typeId;
    final memberId = _memberId;
    if (!_ready() || typeId == null) return;
    if (memberId == null || _reason.text.trim().isEmpty) {
      _toast('اختَر المخدوم واكتب سبب التسجيل');
      return;
    }
    _run(
      _programs.manualScan(
        widget.program.id,
        classId: widget.classId,
        attendanceTypeId: typeId,
        userId: memberId,
        reason: _reason.text.trim(),
      ),
      'تم التسجيل',
    );
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: from ? 'من' : 'إلى',
    );
    if (picked == null || !mounted) return;
    setState(() {
      final day = DateTime(picked.year, picked.month, picked.day);
      if (from) {
        _from = day;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = day;
        if (_to.isBefore(_from)) _from = _to;
      }
    });
    await _loadHistory();
  }

  void _setRange(DateTime from, DateTime to) {
    setState(() {
      _from = DateTime(from.year, from.month, from.day);
      _to = DateTime(to.year, to.month, to.day);
    });
    _loadHistory();
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month && left.day == right.day;

  String _stamp(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _when(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} · $hour:$minute';
  }

  Widget _picker(String label, List<_Choice> options, String? value, ValueChanged<String?> onChanged) {
    if (options.isEmpty) {
      return Text('القائمة بتحمّل', style: TextStyle(color: AppColors.textSecondary));
    }
    final selected = options.any((row) => row.id == value) ? value : options.first.id;
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [for (final option in options) DropdownMenuItem(value: option.id, child: Text(option.label))],
      onChanged: options.isEmpty || _busy ? null : onChanged,
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryMaroon,
        side: BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Text('$label ${_stamp(date)}'),
    );
  }

  Widget _historyCard(Map<String, dynamic> row) {
    final manual = row['manual'] == true;
    final reason = (row['reason'] ?? '').toString().trim();
    final detail = StringBuffer('${row['typeName'] ?? 'حضور'} · ${_when(row['scannedAt'])}');
    detail.write(manual ? ' · يدوي' : ' · مسح');
    if (reason.isNotEmpty) detail.write(' · $reason');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(manual ? Icons.edit_outlined : Icons.qr_code_scanner, color: AppColors.primaryMaroon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (row['name'] ?? 'بدون اسم').toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(detail.toString(), style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${row['pointsAwarded'] ?? 0} نقطة',
            style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final weekStart = todayDay.subtract(Duration(days: (todayDay.weekday + 1) % 7));
    final monthStart = DateTime(today.year, today.month, 1);
    final historyTypes = [const _Choice('', 'كل الأنواع'), ..._types];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _picker('نوع الحضور', _types, _typeId, (value) => setState(() => _typeId = value)),
        const SizedBox(height: 16),
        SubmitButton(text: 'مسح الرمز', onPressed: _busy ? () {} : _scan),
        const SizedBox(height: 20),
        _picker('المخدوم', _members, _memberId, (value) => setState(() => _memberId = value)),
        const SizedBox(height: 12),
        CustomTextField(controller: _reason, labelText: 'سبب التسجيل اليدوي', prefixIcon: Icons.edit_outlined),
        const SizedBox(height: 16),
        SubmitButton(text: 'تسجيل يدوي', onPressed: _busy ? () {} : _manual),
        const SizedBox(height: 8),
        Text(
          'كل مخدوم يتسجل مرة في اليوم للنوع ده. لو النت قاطع، المسح بيتسجل على الجهاز ويتبعت لوحده.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        const Text('سجل الحضور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _picker('نوع السجل', historyTypes, _historyTypeId ?? '', (value) {
          setState(() => _historyTypeId = (value == null || value.isEmpty) ? null : value);
          _loadHistory();
        }),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _dateButton('من', _from, () => _pickDate(from: true)),
            _dateButton('إلى', _to, () => _pickDate(from: false)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('اليوم'),
              selected: _sameDay(_from, todayDay) && _sameDay(_to, todayDay),
              onSelected: (_) => _setRange(todayDay, todayDay),
            ),
            ChoiceChip(
              label: const Text('الأسبوع'),
              selected: _sameDay(_from, weekStart) && _sameDay(_to, todayDay),
              onSelected: (_) => _setRange(weekStart, todayDay),
            ),
            ChoiceChip(
              label: const Text('الشهر'),
              selected: _sameDay(_from, monthStart) && _sameDay(_to, todayDay),
              onSelected: (_) => _setRange(monthStart, todayDay),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField(controller: _search, labelText: 'بحث بالاسم', prefixIcon: Icons.search),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('الكل'),
              selected: _way == 'all',
              onSelected: (_) {
                setState(() => _way = 'all');
                _loadHistory();
              },
            ),
            ChoiceChip(
              label: const Text('مسح الرمز'),
              selected: _way == 'qr',
              onSelected: (_) {
                setState(() => _way = 'qr');
                _loadHistory();
              },
            ),
            ChoiceChip(
              label: const Text('يدوي'),
              selected: _way == 'manual',
              onSelected: (_) {
                setState(() => _way = 'manual');
                _loadHistory();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_historyError != null)
          Text(_historyError!, style: TextStyle(color: AppColors.textSecondary))
        else if (_history.isEmpty)
          Text('مفيش حضور في الفترة دي', style: TextStyle(color: AppColors.textSecondary))
        else ...[
          Text('${_history.length} تسجيل', style: TextStyle(color: AppColors.textSecondary)),
          if (_historyLimited)
            Text('القائمة دي آخر التسجيلات. ضيّق التاريخ لو محتاج الباقي.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          for (final row in _history) _historyCard(row),
        ],
      ],
    );
  }
}
