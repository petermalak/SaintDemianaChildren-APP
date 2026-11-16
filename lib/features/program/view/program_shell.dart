import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/session/session_context.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../authentication/model/user_model.dart';
import '../../profile/repository/i_profile_repository.dart';
import '../repository/i_program_repository.dart';
import 'program_qr_card.dart';
import 'program_quiz_page.dart';
import 'program_scanner.dart';

enum _Tab { home, ledger, quiz, cashout, attendance, followUp, ranking, points, budget, absences, trips }

class ProgramEntry extends StatefulWidget {
  const ProgramEntry({super.key});

  @override
  State<ProgramEntry> createState() => _ProgramEntryState();
}

class _ProgramEntryState extends State<ProgramEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contexts = RoleHelper.membershipContexts(sl<IProfileRepository>().user);
      final selection = contexts.cast<RoleClassSelection?>().firstWhere(
            (row) => row?.programId != null,
            orElse: () => contexts.isEmpty ? null : contexts.first,
          );
      if (selection == null) {
        context.go('/login');
        return;
      }
      SessionContext.instance.select(selection);
      context.go(selection.role == UserRole.makhdoum ? '/makhdoum' : '/khadem');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: AppLoadingView(message: 'جارٍ فتح الحساب'),
    );
  }
}

class ProgramWorkspace extends StatefulWidget {
  final ProgramMembership program;
  final String role;
  final int tabIndex;

  const ProgramWorkspace({
    super.key,
    required this.program,
    required this.role,
    required this.tabIndex,
  });

  static List<AppTabItem> tabs(ProgramMembership program, String role) {
    return [
      for (final tab in _tabIds(program, role))
        AppTabItem(icon: _tabIcon(tab), label: _tabLabel(tab)),
    ];
  }

  static List<_Tab> _tabIds(ProgramMembership program, String role) {
    bool on(String key) => program.features[key] != false;
    final base = <_Tab>[
      _Tab.home,
      _Tab.ledger,
      if (on('quizzes')) _Tab.quiz,
    ];
    final member = <_Tab>[
      ...base,
      if (on('events')) _Tab.trips,
      if (on('cashout')) _Tab.cashout,
    ];
    final score = <_Tab>[
      ...base,
      if (on('evaluation')) _Tab.points,
    ];
    final classServant = <_Tab>[
      ...score,
      if (on('eftekad')) _Tab.followUp,
      if (on('ranking')) _Tab.ranking,
      if (on('events')) _Tab.trips,
    ];
    return switch (role) {
      'amin' => [
        ...classServant,
        if (on('cashout')) _Tab.cashout,
        if (on('budget')) _Tab.budget,
      ],
      'class' => classServant,
      'score' => score,
      _ => member,
    };
  }

  static String _tabLabel(_Tab tab) {
    return switch (tab) {
      _Tab.home => 'الرصيد',
      _Tab.ledger => 'السجل',
      _Tab.quiz => 'المسابقة',
      _Tab.cashout => 'السحب',
      _Tab.attendance => 'الاجتماع',
      _Tab.followUp => 'الافتقاد',
      _Tab.ranking => 'الترتيب',
      _Tab.points => 'النقاط',
      _Tab.budget => 'الميزانية',
      _Tab.absences => 'الغياب',
      _Tab.trips => 'الرحلات',
    };
  }

  static IconData _tabIcon(_Tab tab) {
    return switch (tab) {
      _Tab.home => Icons.home_rounded,
      _Tab.ledger => Icons.receipt_long_rounded,
      _Tab.quiz => Icons.quiz_outlined,
      _Tab.cashout => Icons.payments_rounded,
      _Tab.attendance => Icons.event_note_rounded,
      _Tab.followUp => Icons.favorite_outline,
      _Tab.ranking => Icons.leaderboard_rounded,
      _Tab.points => Icons.emoji_events_rounded,
      _Tab.budget => Icons.account_balance_wallet_rounded,
      _Tab.absences => Icons.person_off_outlined,
      _Tab.trips => Icons.directions_bus_outlined,
    };
  }

  @override
  State<ProgramWorkspace> createState() => _ProgramWorkspaceState();
}

class _ProgramWorkspaceState extends State<ProgramWorkspace> {
  final _programs = sl<IProgramRepository>();
  final _points = TextEditingController(text: '200');
  final _tripPoints = TextEditingController(text: '0');
  final _reason = TextEditingController();
  final _year = TextEditingController();
  final _budgetSearch = TextEditingController();
  String? _budgetClassId;
  final Set<String> _tripMemberIds = {};
  final Map<String, TextEditingController> _settingInputs = {};
  List<Map<String, dynamic>> _kids = const [];
  Map<String, dynamic> _report = const {};

  ProgramMembership get _program => widget.program;
  String get _role => widget.role;
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _catalog = {};
  List<_Choice> _members = const [];
  List<Map<String, dynamic>> _rows = const [];
  String? _classId;
  String? _memberId;
  String? _ruleCode;
  String? _eventId;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _budgetSearch.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant ProgramWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id || oldWidget.role != widget.role) {
      _summary = {};
      _catalog = {};
      _rows = const [];
      _load();
      return;
    }
    if (oldWidget.tabIndex != widget.tabIndex) _loadTab(widget.tabIndex);
  }

  @override
  void dispose() {
    _points.dispose();
    _tripPoints.dispose();
    _reason.dispose();
    _year.dispose();
    _budgetSearch.dispose();
    for (final input in _settingInputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  bool _featureOn(String key) {
    final features = _summary['features'] ?? _program.features;
    return features is! Map || features[key] != false;
  }

  List<_Tab> get _tabs => ProgramWorkspace._tabIds(_program, _role);

  Future<void> _load() async {
    if (_program.id.isEmpty) return;
    setState(() => _loading = _summary.isEmpty);
    final summary = await _programs.summary(_program.id);
    final catalog = await _programs.catalog(_program.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      summary.fold((error) => _error = error, (data) {
        _summary = data;
        _error = null;
      });
      catalog.fold((_) {}, (data) {
        if (data is Map) _catalog = Map<String, dynamic>.from(data);
      });
      _classId ??= _classes.isEmpty ? null : _classes.first.id;
      _ruleCode ??= _rules.isEmpty ? null : _rules.first.id;
      _eventId ??= _events.isEmpty ? null : _events.first['id']?.toString();
      _syncSettingInputs();
    });
    if (_classId != null) await _loadMembers(_classId!);
    await _loadTab(widget.tabIndex);
  }

  Future<void> _loadMembers(String classId) async {
    final result = await _programs.classMembers(_program.id, classId);
    if (!mounted) return;
    result.fold((_) {}, (data) {
      final kids = _asMaps(data);
      final members = kids.map((row) {
        final exempt = row['pointMinimumExempt'] == true;
        final name = (row['name'] ?? 'بدون اسم').toString();
        return _Choice(row['id'].toString(), exempt ? '$name · معفى' : name, exempt: exempt);
      }).toList();
      setState(() {
        _kids = kids;
        _members = members;
        _memberId = members.any((row) => row.id == _memberId) ? _memberId : null;
        _tripMemberIds.removeWhere((id) => !members.any((row) => row.id == id));
      });
    });
  }

  Future<void> _run(Future<dynamic> request, {void Function(dynamic data)? onSuccess, String? done}) async {
    setState(() => _busy = true);
    final result = await request;
    if (!mounted) return;
    result.fold(
      (error) => _toast(error as String),
      (data) {
        if (data is Map && data['queued'] == true) {
          _toast((data['message'] ?? 'اتحفظ المسح على الجهاز وهيتبعت لما النت يرجع').toString());
          return;
        }
        onSuccess?.call(data);
        if (done != null) _toast(done);
      },
    );
    if (mounted) setState(() => _busy = false);
    await _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTab(int index) async {
    final tabs = _tabs;
    if (tabs.isEmpty) return;
    final tab = tabs[index.clamp(0, tabs.length - 1)];
    if (tab != _Tab.ranking && tab != _Tab.budget && tab != _Tab.cashout && tab != _Tab.absences && tab != _Tab.followUp && tab != _Tab.trips) {
      return;
    }
    if (mounted) setState(() => _rows = const []);
    if (tab == _Tab.ranking) {
      await _fill(_programs.rankings(_program.id));
    } else if (tab == _Tab.budget) {
      await _fill(_programs.budget(_program.id), single: true);
      final report = await _programs.report(_program.id);
      if (!mounted) return;
      report.fold((_) {}, (data) {
        if (data is Map) setState(() => _report = Map<String, dynamic>.from(data));
      });
      _syncSettingInputs();
    } else if (tab == _Tab.cashout) {
      await _fill(_programs.cashouts(_program.id));
    } else if (tab == _Tab.absences || tab == _Tab.followUp) {
      await _fill(_programs.absences(_program.id));
    } else if (tab == _Tab.trips) {
      await _loadBookings();
    }
  }

  Future<void> _fill(Future<dynamic> request, {bool single = false}) async {
    final result = await request;
    if (!mounted) return;
    result.fold(_toast, (data) {
      setState(() {
        _rows = single && data is Map ? [Map<String, dynamic>.from(data)] : _asMaps(data);
      });
    });
  }

  List<_Choice> get _classes {
    final fromCatalog = _asMaps(_catalog['classes'])
        .map((row) => _Choice(row['id'].toString(), (row['name'] ?? 'فصل').toString()))
        .where((row) => _program.classIds == null || _program.classIds!.contains(row.id))
        .toList();
    if (fromCatalog.isNotEmpty) return fromCatalog;
    final user = sl<IProfileRepository>().user;
    return (user?.classes ?? const <UserClassInfo>[])
        .where((row) => _program.classIds == null || _program.classIds!.contains(row.classId))
        .map((row) => _Choice(row.classId, row.className ?? 'فصل'))
        .toList();
  }

  List<_Choice> get _rules {
    return _asMaps(_catalog['pointRules'])
        .where((row) => row['isActive'] != false && _canRecord(row['recordedBy']?.toString()))
        .map((row) => _Choice(row['code'].toString(), '${row['name']} · ${row['points']} نقطة'))
        .toList();
  }

  bool _canRecord(String? recordedBy) {
    if (recordedBy == 'system') return false;
    if (_role == 'score') return recordedBy == 'score_servant';
    return _role == 'class' || _role == 'amin';
  }

  @override
  Widget build(BuildContext context) {
    if (_program.id.isEmpty) {
      return const AppEmptyView(title: 'لا يوجد برنامج على هذا الحساب', icon: Icons.groups_outlined);
    }
    if (_loading) return const AppLoadingView(message: 'جارٍ تحميل البرنامج');
    if (_error != null && _summary.isEmpty) return AppErrorView(message: _error!, onRetry: _load);
    final tabs = _tabs;
    final index = widget.tabIndex.clamp(0, tabs.length - 1);
    if (tabs[index] == _Tab.quiz) {
      return ProgramQuizPage(
        key: ValueKey('${_program.id}-$_role'),
        programId: _program.id,
        canPublish: _role == 'score' || _role == 'class' || _role == 'amin',
      );
    }
    return _page(tabs[index]);
  }

  Widget _page(_Tab tab) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: switch (tab) {
        _Tab.home => _home(),
        _Tab.ledger => _ledger(),
        _Tab.quiz => const [],
        _Tab.cashout => _cashoutPage(),
        _Tab.attendance => const [Text('حضور الخدمة يتسجل من تبويب الحضور')],
        _Tab.followUp => _followUp(),
        _Tab.ranking => _ranking(),
        _Tab.points => _pointsForm(),
        _Tab.budget => _budget(),
        _Tab.absences => _namedRows('مفيش غياب محتاج متابعة'),
        _Tab.trips => _trips(),
      },
    );
  }

  List<Widget> _home() {
    final points = _summary['available']?.toString() ?? _summary['points']?.toString() ?? '0';
    final level = _summary['level'] is Map ? _summary['level']['name']?.toString() ?? '' : '';
    final user = sl<IProfileRepository>().user;
    final qr = _summary['qr'];
    final token = qr is Map ? qr['token']?.toString() : null;
    final expires = qr is Map ? int.tryParse('${qr['expiresIn']}') ?? 45 : 45;
    final notices = _asMaps(_summary['notices']);
    return [
      _hero(
        title: 'أهلاً ${firstNameOf(user?.name, fallback: 'المخدوم')}',
        subtitle: _roleGuide(),
        value: points,
        caption: 'المتاح',
      ),
      if (_featureOn('levels') && level.isNotEmpty) ...[
        const SizedBox(height: 12),
        _infoCard(Icons.military_tech_outlined, 'المستوى', level),
      ],
      const SizedBox(height: 12),
      _infoCard(Icons.payments_outlined, 'المحفظة', 'المصروف ${_summary['spent'] ?? 0} · المكتسب ${_summary['earned'] ?? 0}'),
      if (_featureOn('streak')) ...[
        const SizedBox(height: 12),
        _infoCard(Icons.local_fire_department_outlined, 'سلسلة الحضور', '${_summary['streakWeeks'] ?? 0} أسبوع'),
      ],
      if (_featureOn('qr') && _role != 'score' && _role != 'class' && _role != 'amin' && token != null) ...[
        const SizedBox(height: 12),
        ProgramQrCard(programId: _program.id, programs: _programs, initialToken: token, expiresIn: expires),
      ],
      if (notices.isNotEmpty) ...[
        const SizedBox(height: 12),
        for (final notice in notices.take(5)) ...[
          _infoCard(Icons.notifications_none, (notice['title'] ?? 'إشعار').toString(), (notice['body'] ?? '').toString()),
          const SizedBox(height: 12),
        ],
      ],
      if (_role == 'amin') ...[
        const SizedBox(height: 12),
        _infoCard(Icons.event_available_outlined, 'إقفال السنة', 'الترحيل يسيب ${(_summary['settings'] is Map ? _summary['settings']['carryOverMax'] : null) ?? 500} نقطة والباقي ينتهي'),
        const SizedBox(height: 12),
        SubmitButton(text: 'تنفيذ الترحيل', onPressed: _busy ? () {} : () => _run(_programs.carryOver(_program.id), done: 'الترحيل اتنفذ')),
        const SizedBox(height: 12),
        CustomTextField(controller: _year, labelText: 'السنة الخدمية', prefixIcon: Icons.calendar_today_outlined),
        const SizedBox(height: 12),
        SubmitButton(text: 'معاينة نقل الفصول', onPressed: _busy ? () {} : _previewYear),
        const SizedBox(height: 12),
        SubmitButton(text: 'تنفيذ نقل الفصول', onPressed: _busy ? () {} : _applyYear),
      ],
      const SizedBox(height: 20),
      TextButton(onPressed: _busy ? null : _eraseData, child: const Text('حذف بيانات الخدمة')),
      TextButton(onPressed: _busy ? null : _deleteAccount, child: const Text('حذف الحساب')),
    ];
  }

  List<Widget> _ledger() {
    final rows = _asMaps(_summary['ledger']);
    if (rows.isEmpty) return [_empty('لسه مفيش حركات')];
    return [
      for (final row in rows) ...[
        _infoCard(
          Icons.toll_outlined,
          _sourceLabel(row['source']?.toString()),
          '${_formatDate(row['createdAt'])} · ${row['recordedByName'] ?? 'النظام'} · ${row['note'] ?? ''}',
          trailing: '${row['points'] ?? 0}',
        ),
        if (_role == 'amin' && row['source'] != 'reversal' && row['reversalOf'] == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy ? null : () => _run(_programs.reverseLedger(row['id'].toString()), done: 'اتسجل تصحيح عكسي'),
              child: const Text('تصحيح عكسي'),
            ),
          ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _followUp() {
    return [
      _picker('الفصل', _classes, _classId, (value) {
        setState(() => _classId = value);
        if (value != null) _loadMembers(value);
      }),
      const SizedBox(height: 12),
      _picker('المخدوم', _members, _memberId, (value) => setState(() => _memberId = value)),
      if (_memberId != null && (_role == 'class' || _role == 'amin')) ...[
        const SizedBox(height: 4),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _members.any((row) => row.id == _memberId && row.exempt),
          onChanged: _busy ? null : (value) => _setExemption(value == true),
          title: const Text('إعفاء من 25%'),
          subtitle: const Text('حجز الرحلة من غير شرط ربع السعر من التوكن'),
        ),
      ],
      const SizedBox(height: 12),
      CustomTextField(controller: _reason, labelText: 'ملاحظة الافتقاد', prefixIcon: Icons.notes_outlined),
      const SizedBox(height: 16),
      SubmitButton(text: 'تم الافتقاد', onPressed: _busy ? () {} : _markEftekad),
      const SizedBox(height: 20),
      const Text('أولادي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      ..._kidCards(),
      const SizedBox(height: 12),
      ..._namedRows('مفيش غياب محتاج متابعة'),
    ];
  }

  List<Map<String, dynamic>> get _events => _asMaps(_catalog['events']);

  Map<String, dynamic>? get _selectedEvent {
    for (final event in _events) {
      if (event['id']?.toString() == _eventId) return event;
    }
    return _events.isEmpty ? null : _events.first;
  }

  Future<void> _bookTrip() async {
    final event = _selectedEvent;
    if (event == null || _tripMemberIds.isEmpty) {
      _toast('اختار الرحلة والأولاد');
      return;
    }
    final points = int.tryParse(_tripPoints.text) ?? 0;
    final price = int.tryParse('${event['price']}') ?? 0;
    final percent = int.tryParse('${event['minPointPercent']}') ?? 25;
    final minimum = ((price * percent) / 100).ceil();
    final needsMinimum = _members.any((row) => _tripMemberIds.contains(row.id) && !row.exempt);
    if (needsMinimum && points < minimum) {
      _toast('غير المعفيين محتاجين $minimum نقطة على الأقل');
      return;
    }
    setState(() => _busy = true);
    var booked = 0;
    for (final userId in _tripMemberIds) {
      final result = await _programs.bookEvent(event['id'].toString(), userId: userId, points: points);
      if (!mounted) return;
      final failed = result.fold((error) {
        _toast(error);
        return true;
      }, (_) => false);
      if (failed) break;
      booked += 1;
    }
    if (mounted) {
      setState(() => _busy = false);
      if (booked == _tripMemberIds.length) _toast('تم حجز الرحلة');
    }
  }

  List<Widget> _trips() {
    if (_role != 'class' && _role != 'amin') return _bookingCards();
    final event = _selectedEvent;
    if (event == null) return [_empty('لسه مفيش رحلات')];
    final price = int.tryParse('${event['price']}') ?? 0;
    final percent = int.tryParse('${event['minPointPercent']}') ?? 25;
    final minimum = ((price * percent) / 100).ceil();
    final rules = _asMaps(event['refundRules']);
    final ruleText = rules.isEmpty
        ? 'الإلغاء: قبل شهر كامل، وقبل 3 أسابيع 75%'
        : rules.map((rule) => 'قبل ${rule['daysBefore']} يوم = ${rule['refundPercent']}%').join(' · ');
    final choices = [
      for (final row in _events)
        _Choice(row['id'].toString(), '${row['title']} · ${row['price']} جنيه'),
    ];
    return [
      _infoCard(Icons.directions_bus_outlined, 'حجز الرحلة', 'خادم الفصل يختار الأولاد. الشرط $percent% من السعر، يعني $minimum نقطة. المتبقي كاش. $ruleText'),
      const SizedBox(height: 12),
      _picker('الرحلة', choices, _eventId ?? event['id']?.toString(), (value) {
        setState(() => _eventId = value);
        _loadBookings();
      }),
      const SizedBox(height: 12),
      _picker('الفصل', _classes, _classId, (value) {
        setState(() {
          _classId = value;
          _tripMemberIds.clear();
        });
        if (value != null) _loadMembers(value);
      }),
      const SizedBox(height: 8),
      if (_members.isEmpty)
        _empty('مفيش أولاد في الفصل')
      else
        for (final member in _members)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _tripMemberIds.contains(member.id),
            onChanged: _busy
                ? null
                : (value) => setState(() {
                      if (value == true) {
                        _tripMemberIds.add(member.id);
                      } else {
                        _tripMemberIds.remove(member.id);
                      }
                    }),
            title: Text(member.label),
            subtitle: Text(member.exempt ? 'معفى من شرط الـ $percent%' : 'مطلوب $minimum نقطة على الأقل'),
          ),
      const SizedBox(height: 8),
      CustomTextField(
        controller: _tripPoints,
        labelText: 'نقط التوكن لكل ولد',
        prefixIcon: Icons.toll_outlined,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      SubmitButton(text: 'حجز الرحلة', onPressed: _busy ? () {} : _bookTrip),
      const SizedBox(height: 12),
      SubmitButton(text: 'حضور بالرمز', onPressed: _busy ? () {} : _attendByCode),
      const SizedBox(height: 20),
      const Text('الحجوزات وقائمة الانتظار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      ..._bookingCards(),
    ];
  }

  Future<void> _setExemption(bool exempt) async {
    final memberId = _memberId;
    if (memberId == null) return;
    await _run(
      _programs.setPointExemption(_program.id, userId: memberId, exempt: exempt),
      done: exempt ? 'اتعفى من شرط الـ 25%' : 'اتشال الإعفاء',
    );
  }

  List<Widget> _pointsForm() {
    return [
      _picker('البند', _rules, _ruleCode, (value) => setState(() => _ruleCode = value)),
      const SizedBox(height: 12),
      _picker('الفصل', _classes, _classId, (value) {
        setState(() => _classId = value);
        if (value != null) _loadMembers(value);
      }),
      const SizedBox(height: 12),
      _picker('الاسم', _members, _memberId, (value) => setState(() => _memberId = value)),
      const SizedBox(height: 16),
      SubmitButton(text: 'تسجيل البند', onPressed: _busy ? () {} : _recordPoints),
    ];
  }

  List<Widget> _cashoutPage() {
    if (_role == 'amin') {
      return [
        _infoCard(Icons.payments_outlined, 'طلبات السحب', 'الموافقة والرفض للأمين. النقط بتتحجز من المخدوم لحد الرد.'),
        const SizedBox(height: 12),
        ..._cashoutRows(),
      ];
    }
    return [
      _infoCard(Icons.directions_bus_outlined, 'الرحلات أولاً', 'صرف التوكن على الرحلات من تبويب الرحلات، والسحب الكاش تحت.'),
      const SizedBox(height: 12),
      ..._cashoutForm(),
      const SizedBox(height: 20),
      ..._cashoutRows(),
    ];
  }

  List<Widget> _cashoutForm() {
    return [
      CustomTextField(
        controller: _points,
        labelText: 'نقاط السحب',
        prefixIcon: Icons.payments_outlined,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      SubmitButton(
        text: 'طلب سحب',
        onPressed: _busy ? () {} : () => _run(_programs.requestCashout(_program.id, int.tryParse(_points.text) ?? 0), done: 'تم إرسال الطلب'),
      ),
    ];
  }

  List<Widget> _budget() {
    if (_rows.isEmpty) return [_empty('مفيش ميزانية ظاهرة')];
    final row = _rows.first;
    final paused = row['manualPause'] == true || row['cashoutPaused'] == true;
    return [
      _hero(
        title: 'المصروف',
        subtitle: 'من ${_pounds(row['expected'])} متوقعة',
        value: _grouped(row['spent']),
        caption: 'جنيه',
      ),
      const SizedBox(height: 12),
      _infoCard(Icons.flag_outlined, 'السقف', 'حد الصرف في السنة', trailing: _pounds(row['ceiling'])),
      const SizedBox(height: 12),
      _infoCard(Icons.savings_outlined, 'المتبقي', 'بعد المصروف اللي اتوافق عليه', trailing: _pounds(row['remaining'])),
      const SizedBox(height: 12),
      _infoCard(Icons.insights_outlined, 'توقع آخر السنة', 'لو الصرف كمّل بنفس المعدل', trailing: _pounds(row['forecast'])),
      const SizedBox(height: 12),
      _infoCard(Icons.toll_outlined, 'نقط صدرت', 'كل اللي اتضاف للأولاد', trailing: _pointText(row['issued'])),
      const SizedBox(height: 12),
      _infoCard(Icons.account_balance_wallet_outlined, 'لسه في الحسابات', 'نقط موجودة وماتصرفتش', trailing: _pointText(row['liability'])),
      if (row['alert'] != null) ...[
        const SizedBox(height: 12),
        _infoCard(Icons.warning_amber_outlined, 'تنبيه السقف', 'المصروف وصل ${row['alert']}% من السقف'),
      ],
      const SizedBox(height: 12),
      _infoCard(Icons.pause_circle_outline, 'السحب الكاش', paused ? 'واقف. الرحلات لسه بتتصرف بالنقط.' : 'شغال'),
      const SizedBox(height: 8),
      SubmitButton(
        text: row['manualPause'] == true ? 'تشغيل السحب' : 'إيقاف السحب',
        onPressed: _busy ? () {} : () => _run(_programs.setCashoutPaused(_program.id, paused: row['manualPause'] != true), done: 'اتحدث السحب'),
      ),
      const SizedBox(height: 20),
      _sectionTitle('المتابعة'),
      _infoCard(Icons.event_available_outlined, 'حضور الأسبوع', 'نسبة الأولاد اللي سجلوا حضور', trailing: '${_report['weeklyAttendanceRate'] ?? 0}%'),
      const SizedBox(height: 12),
      _infoCard(Icons.people_outline, 'النشطون هذا الشهر', 'من ${_grouped(_report['members'])} مخدوم', trailing: _grouped(_report['monthlyActive'])),
      const SizedBox(height: 12),
      _infoCard(Icons.favorite_outline, 'افتقاد الغياب', 'اللي تمت متابعتهم خلال أسبوع', trailing: '${_report['eftekadFollowRate'] ?? 0}%'),
      const SizedBox(height: 12),
      _infoCard(Icons.account_balance_outlined, 'الصندوق من الميزانية', 'المصروف مقارنة بالمتوقع', trailing: '${_report['costVersusBudget'] ?? 0}%'),
      const SizedBox(height: 20),
      _sectionTitle('تصفية القوائم'),
      CustomTextField(controller: _budgetSearch, labelText: 'بحث بالاسم', prefixIcon: Icons.search),
      const SizedBox(height: 12),
      _budgetClassPicker(),
      const SizedBox(height: 8),
      Text(
        'بحث الاسم بيظبط الغياب والخدام. اختيار الفصل بيظبط حضور الشهر كمان.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 20),
      ..._classAttendanceCards(),
      ..._fundCards(),
      _sectionTitle('المواظبة والغياب'),
      _infoCard(Icons.emoji_events_outlined, 'المواظبون', 'وصلوا 4 أسابيع متتالية', trailing: _grouped(_report['regulars'])),
      const SizedBox(height: 12),
      ..._absenceCards(),
      ..._servantCards(),
      ..._anomalyCards(),
      if ((_report['exportText'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('نسخة للمتابعة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          children: [
            SelectableText(_report['exportText'].toString(), style: TextStyle(color: AppColors.textSecondary, height: 1.6)),
          ],
        ),
      ],
      const SizedBox(height: 8),
      ..._settingsForm(),
    ];
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
    );
  }

  List<Widget> _namedRows(String empty) {
    if (_rows.isEmpty) return [_empty(empty)];
    return [
      for (final row in _rows) ...[
        _infoCard(
          Icons.person_outline,
          (row['name'] ?? row['title'] ?? 'عنصر').toString(),
          _rowDetail(row),
          trailing: row['points']?.toString() ?? row['average']?.toString(),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  String _rowDetail(Map<String, dynamic> row) {
    if (row['missed'] != null) return 'غياب ${row['missed']} أسبوع';
    if (row['status'] != null) return _statusLabel(row['status'].toString());
    if (row['average'] != null) return 'متوسط النقاط';
    return '';
  }

  Widget _hero({required String title, required String subtitle, required String value, required String caption}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryMaroon.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.accentWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: AppColors.accentWhite.withValues(alpha: 0.9), fontSize: 14)),
              ],
            ),
          ),
          Column(
            children: [
              Text(value, style: const TextStyle(color: AppColors.accentGold, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(caption, style: const TextStyle(color: AppColors.accentWhite, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle, {String? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryMaroon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _empty(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.primaryMaroon.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _picker(String label, List<_Choice> options, String? value, ValueChanged<String?> onChanged) {
    final selected = options.any((row) => row.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primaryMaroon, width: 2),
        ),
      ),
      items: [for (final option in options) DropdownMenuItem(value: option.id, child: Text(option.label))],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }

  Future<void> _attendByCode() async {
    final eventId = _eventId;
    if (eventId == null) return;
    final token = await showProgramScanner(context);
    if (token == null || !mounted) return;
    await _run(_programs.attendEvent(eventId, token: token), done: 'حضور الرحلة اتسجل');
  }

  Future<void> _loadBookings() async {
    final eventId = _eventId;
    final request = (_role == 'class' || _role == 'amin') && eventId != null
        ? _programs.eventBookings(eventId)
        : _programs.myBookings(_program.id);
    await _fill(request);
  }

  void _syncSettingInputs() {
    if (_role != 'amin') return;
    final settings = _catalog['settings'];
    if (settings is! Map) return;
    for (final key in _settingLabels.keys) {
      _settingInputs.putIfAbsent(key, () => TextEditingController(text: '${settings[key] ?? ''}'));
    }
  }

  List<Widget> _settingsForm() {
    if (_settingInputs.isEmpty) return const [Text('الإعدادات بتحمل')];
    return [
      for (final group in _settingGroups) ...[
        const SizedBox(height: 12),
        _sectionTitle(group.$1),
        for (final entry in group.$2.entries) ...[
          CustomTextField(
            controller: _settingInputs[entry.key]!,
            labelText: entry.value,
            prefixIcon: Icons.tune,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
        ],
      ],
      const SizedBox(height: 8),
      SubmitButton(text: 'حفظ الإعدادات', onPressed: _busy ? () {} : _saveSettings),
    ];
  }

  void _saveSettings() {
    final body = <String, dynamic>{
      for (final entry in _settingInputs.entries) entry.key: num.tryParse(entry.value.text) ?? entry.value.text,
    };
    _run(_programs.saveSettings(_program.id, body), done: 'الإعدادات اتسجلت');
  }

  List<Widget> _kidCards() {
    if (_kids.isEmpty) return [_empty('مفيش أولاد في الفصل')];
    return [
      for (final kid in _kids) ...[
        _infoCard(
          Icons.child_care_outlined,
          (kid['name'] ?? 'مخدوم').toString(),
          'آخر حضور ${_formatDate(kid['lastAttendance'])} · غياب ${kid['missedWeeks'] ?? 0} أسبوع${kid['phoneNumber'] == null ? '' : ' · ${kid['phoneNumber']}'}',
          trailing: '${kid['points'] ?? 0}',
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _ranking() {
    if (_rows.isEmpty) return [_empty('لسه مفيش ترتيب')];
    return [
      for (final row in _rows) ...[
        _infoCard(Icons.groups_outlined, (row['name'] ?? 'فصل').toString(), 'متوسط الفصل', trailing: '${row['average'] ?? 0}'),
        const SizedBox(height: 8),
        for (final person in _asMaps(row['people'])) ...[
          _infoCard(Icons.person_outline, (person['name'] ?? 'مخدوم').toString(), 'ترتيب الأفراد', trailing: '${person['points'] ?? 0}'),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  List<Widget> _bookingCards() {
    if (_rows.isEmpty) return [_empty('لسه مفيش حجوزات')];
    final canManage = _role == 'class' || _role == 'amin';
    return [
      for (final row in _rows) ...[
        _infoCard(
          Icons.event_seat_outlined,
          (row['name'] ?? row['title'] ?? 'حجز').toString(),
          _bookingDetail(row),
          trailing: '${row['points'] ?? 0}',
        ),
        if (canManage && row['status'] != 'refunded')
          Wrap(
            children: [
              TextButton(
                onPressed: _busy ? null : () => _run(_programs.markCashPaid(row['id'].toString()), done: 'تسجيل الكاش اتحدث'),
                child: Text(row['cashPaidAt'] == null ? 'الكاش اتدفع' : 'إلغاء تسجيل الكاش'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _run(_programs.refundBooking(row['id'].toString()), done: 'الحجز اتلغى'),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: _busy || row['userId'] == null
                    ? null
                    : () => _run(
                          _programs.attendEvent((row['eventId'] ?? _eventId).toString(), userId: row['userId'].toString()),
                          done: 'الحضور اتسجل',
                        ),
                child: const Text('حضور'),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    ];
  }

  String _bookingDetail(Map<String, dynamic> row) {
    final points = int.tryParse('${row['points']}') ?? 0;
    final cash = row['cash'] ?? 0;
    final paid = row['cashPaidAt'] != null ? 'الكاش اتسجل' : 'الكاش لسه';
    final attended = row['attendedAt'] != null ? ' · حضر' : '';
    return '${_statusLabel('${row['status']}')} · $points نقطة · المتبقي $cash جنيه · $paid · ${_formatDate(row['bookedAt'])}$attended';
  }

  List<Widget> _cashoutRows() {
    if (_rows.isEmpty) return [_empty('مفيش طلبات سحب')];
    return [
      for (final row in _rows) ...[
        _infoCard(
          Icons.payments_outlined,
          (row['name'] ?? 'طلب').toString(),
          _statusLabel('${row['status']}'),
          trailing: '${row['points'] ?? 0}',
        ),
        if (_role == 'amin' && row['status'] == 'pending')
          Row(
            children: [
              TextButton(
                onPressed: _busy ? null : () => _run(_programs.reviewCashout(row['id'].toString(), approve: true), done: 'تمت الموافقة'),
                child: const Text('موافقة'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _run(_programs.reviewCashout(row['id'].toString(), approve: false), done: 'الطلب اترفض والنقط رجعت'),
                child: const Text('رفض'),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _absenceCards() {
    final all = _asMaps(_report['longAbsence']);
    final rows = all.where(_budgetRowMatches).toList();
    if (rows.isEmpty) {
      return [
        _infoCard(
          Icons.check_circle_outline,
          'الغياب الطويل',
          _budgetFilterOn && all.isNotEmpty ? 'مفيش نتيجة بالفلتر ده' : 'مفيش حد غايب فترة طويلة',
        ),
        const SizedBox(height: 12),
      ];
    }
    return [
      for (final row in rows) ...[
        _infoCard(
          Icons.person_off_outlined,
          (row['name'] ?? 'مخدوم').toString(),
          '${_className(row['classId'])} · غايب ${row['missed'] ?? 0} أسابيع',
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _servantCards() {
    final rows = _asMaps(_report['servants']).where(_budgetRowMatches).toList();
    if (rows.isEmpty) {
      if (!_budgetFilterOn) return const [];
      return [
        const SizedBox(height: 8),
        _sectionTitle('الخدام'),
        _infoCard(Icons.badge_outlined, 'الخدام', 'مفيش نتيجة بالفلتر ده'),
        const SizedBox(height: 12),
      ];
    }
    final byClass = <String, List<String>>{};
    for (final row in rows) {
      final className = (row['className'] ?? _className(row['classId'])).toString();
      final name = (row['name'] ?? 'خادم').toString();
      byClass.putIfAbsent(className, () => []).add(name);
    }
    final names = byClass.keys.toList()..sort();
    return [
      const SizedBox(height: 8),
      _sectionTitle('الخدام'),
      for (final className in names) ...[
        _infoCard(Icons.badge_outlined, className, byClass[className]!.join('، ')),
        const SizedBox(height: 12),
      ],
    ];
  }

  bool get _budgetFilterOn => _budgetClassId != null || _budgetSearch.text.trim().isNotEmpty;

  bool _budgetRowMatches(Map<String, dynamic> row) {
    if (_budgetClassId != null && row['classId']?.toString() != _budgetClassId) return false;
    final query = _budgetSearch.text.trim();
    if (query.isEmpty) return true;
    return (row['name'] ?? '').toString().contains(query);
  }

  Map<String, String> get _classNames => {
        for (final row in _asMaps(_catalog['classes'])) row['id'].toString(): (row['name'] ?? 'فصل').toString(),
      };

  String _className(dynamic id) => _classNames[id?.toString()] ?? 'فصل';

  Widget _budgetClassPicker() {
    final options = [
      const _Choice('', 'كل الفصول'),
      for (final entry in _classNames.entries) _Choice(entry.key, entry.value),
    ];
    return _picker('الفصل', options, _budgetClassId ?? '', (value) {
      setState(() => _budgetClassId = (value == null || value.isEmpty) ? null : value);
    });
  }

  List<Widget> _classAttendanceCards() {
    final raw = _report['attendanceByClass'];
    if (raw is! Map || raw.isEmpty) return const [];
    final names = _classNames;
    final entries = raw.entries.where((entry) => _budgetClassId == null || entry.key.toString() == _budgetClassId).toList()
      ..sort((left, right) => (_number(right.value)).compareTo(_number(left.value)));
    if (entries.isEmpty) {
      return [
        _sectionTitle('حضور الشهر حسب الفصل'),
        _infoCard(Icons.groups_outlined, _className(_budgetClassId), 'مفيش حضور للفصل ده هذا الشهر'),
        const SizedBox(height: 20),
      ];
    }
    return [
      _sectionTitle('حضور الشهر حسب الفصل'),
      for (final entry in entries) ...[
        _infoCard(
          Icons.groups_outlined,
          names[entry.key.toString()] ?? 'فصل',
          'مرات الحضور هذا الشهر',
          trailing: _grouped(entry.value),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _fundCards() {
    final raw = _report['fund'];
    if (raw is! Map || raw.isEmpty) return const [];
    final entries = raw.entries.where((entry) => _number(entry.value) != 0).toList()
      ..sort((left, right) => _number(right.value).compareTo(_number(left.value)));
    if (entries.isEmpty) return const [];
    return [
      _sectionTitle('حركة النقط'),
      for (final entry in entries) ...[
        _infoCard(Icons.swap_vert, _sourceLabel(entry.key.toString()), 'مجموع الحركة', trailing: _pointText(entry.value)),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 8),
    ];
  }

  num _number(dynamic value) => num.tryParse('$value') ?? 0;

  String _grouped(dynamic value) {
    final number = _number(value);
    final negative = number < 0;
    final digits = number.abs().round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  String _pounds(dynamic value) => '${_grouped(value)} جنيه';

  String _pointText(dynamic value) => '${_grouped(value)} نقطة';

  List<Widget> _anomalyCards() {
    final rows = _asMaps(_report['anomalies']);
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      _sectionTitle('تسجيل يدوي متكرر'),
      for (final row in rows) ...[
        _infoCard(Icons.report_outlined, 'نفس المخدوم', 'اتسجل يدوي ${_grouped(row['count'])} مرات'),
        const SizedBox(height: 12),
      ],
    ];
  }

  Future<String?> _askPhrase(String title, String phrase) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: input, decoration: InputDecoration(hintText: phrase)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
          TextButton(onPressed: () => Navigator.pop(context, input.text.trim()), child: const Text('تأكيد')),
        ],
      ),
    );
    input.dispose();
    return value;
  }

  Future<void> _eraseData() async {
    final phrase = await _askPhrase('حذف بيانات الخدمة', 'احذف بياناتي');
    if (phrase == null || !mounted) return;
    await _run(_programs.eraseData(_program.id, phrase), done: 'بيانات الخدمة اتمسحت');
  }

  Future<void> _deleteAccount() async {
    final phrase = await _askPhrase('حذف الحساب', 'احذف حسابي');
    if (phrase == null || !mounted) return;
    setState(() => _busy = true);
    final result = await _programs.deleteAccount(phrase);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(_toast, (_) {
      sl<IProfileRepository>().user = null;
      context.go('/login');
    });
  }

  void _applyYear() {
    if (_year.text.trim().isEmpty) {
      _toast('اكتب السنة الخدمية');
      return;
    }
    _run(_programs.yearClose(_program.id, _year.text.trim()), done: 'نقل الفصول اتنفذ');
  }

  String _roleGuide() {
    return switch (_role) {
      'amin' => 'أمين الخدمة. شايف كل الفصول، الميزانية، السحب، والرحلات.',
      'class' => 'خادم الفصل. شغلك على أولاد فصلك: الحضور، الافتقاد، والنقاط.',
      'score' => 'خادم السكور. تسجّل بنود النقاط. الحضور والرحلات عند خادم الفصل.',
      _ => 'مخدوم. رصيدك ورمزك ومسابقتك ورحلاتك وطلب السحب.',
    };
  }

  void _markEftekad() {
    final classId = _classId;
    final memberId = _memberId;
    if (classId == null || memberId == null) {
      _toast('اختَر الفصل والمخدوم');
      return;
    }
    _run(
      _programs.markEftekad(_program.id, classId: classId, userId: memberId, note: _reason.text.trim()),
      done: 'تم تسجيل الافتقاد',
    );
  }

  void _recordPoints() {
    final classId = _classId;
    final memberId = _memberId;
    final rule = _ruleCode;
    if (classId == null || memberId == null || rule == null || rule.isEmpty) {
      _toast('اختَر البند والفصل والاسم');
      return;
    }
    _run(
      _programs.recordPoints(_program.id, ruleCode: rule, classId: classId, userId: memberId),
      done: 'تم تسجيل البند',
    );
  }

  Future<void> _previewYear() async {
    final result = await _programs.yearClosePreview(_program.id);
    if (!mounted) return;
    result.fold(_toast, (data) {
      final moves = data is Map && data['moves'] is List ? (data['moves'] as List).length : 0;
      final exceptions = data is Map && data['exceptions'] is List ? (data['exceptions'] as List).length : 0;
      _toast('النقل $moves · الاستثناءات $exceptions');
    });
  }

  String _sourceLabel(String? source) {
    return switch (source) {
      'attendance' => 'حضور',
      'cashout' => 'سحب',
      'cashout_hold' => 'حجز سحب',
      'rule' => 'بند',
      'streak' => 'سلسلة',
      'event' => 'رحلة',
      'refund' => 'استرداد',
      'reversal' => 'تصحيح',
      'expiry' => 'انتهاء',
      _ => 'حركة',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'في الانتظار',
      'approved' => 'موافق عليه',
      'rejected' => 'مرفوض',
      'booked' => 'محجوز',
      'waitlist' => 'قائمة الانتظار',
      'refunded' => 'ملغي',
      _ => status,
    };
  }

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

const _settingGroups = <(String, Map<String, String>)>[
  ('الميزانية', {
    'budgetExpected': 'الميزانية المتوقعة',
    'budgetCeiling': 'سقف الميزانية',
  }),
  ('النقط', {
    'pointValueEgp': 'قيمة النقطة بالجنيه',
    'annualCap': 'السقف السنوي للنقط',
    'carryOverMax': 'أقصى ترحيل في نهاية السنة',
  }),
  ('السحب والرحلات', {
    'cashoutMin': 'أقل سحب',
    'cashoutsPerQuarter': 'مرات السحب في الربع',
    'eventMinPointPercent': 'أقل نسبة توكن للرحلة',
  }),
  ('الالتزام والرمز', {
    'commitmentMonthlyPoints': 'نقاط الالتزام',
    'commitmentWeeks': 'أسابيع الالتزام في الشهر',
    'qrRotateSeconds': 'تجديد الرمز بالثواني',
  }),
];

Map<String, String> get _settingLabels => {
  for (final group in _settingGroups) ...group.$2,
};

class _Choice {
  final String id;
  final String label;
  final bool exempt;

  const _Choice(this.id, this.label, {this.exempt = false});
}

List<Map<String, dynamic>> _asMaps(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
}
