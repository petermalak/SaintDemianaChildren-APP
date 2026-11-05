import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../profile/repository/i_profile_repository.dart';
import '../../model/agenda_model.dart';
import '../../repository/i_agenda_repository.dart';

class PopeAthanasiusAgendaScreen extends StatefulWidget {
  const PopeAthanasiusAgendaScreen({super.key});

  @override
  State<PopeAthanasiusAgendaScreen> createState() =>
      _PopeAthanasiusAgendaScreenState();
}

class _PopeAthanasiusAgendaScreenState extends State<PopeAthanasiusAgendaScreen> {
  static const _phases = <int, String>{
    1: 'الفرقة الأولى',
    2: 'الفرقة الثانية',
    3: 'الفرقة الثالثة',
    4: 'الفرقة الرابعة',
  };

  int? _selectedPhase;
  PhaseAgenda? _agenda;
  bool _loading = true;
  String? _error;

  bool get _canBrowsePhases {
    final role = sl<IProfileRepository>().user?.role;
    return role == 'khadem' || role == 'admin' || role == 'super_admin';
  }

  @override
  void initState() {
    super.initState();
    final ownPhase = sl<IProfileRepository>().user?.popeAthnasiusMeetingData?.studyLevel;
    if (_canBrowsePhases) {
      _selectedPhase = (ownPhase != null && ownPhase >= 1 && ownPhase <= 4) ? ownPhase : 1;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = sl<IAgendaRepository>();
    final result = _selectedPhase == null
        ? await repo.getMyAgenda()
        : await repo.getAgendaForPhase(_selectedPhase!);
    if (!mounted) return;
    result.fold(
      (message) => setState(() {
        _loading = false;
        _error = message;
      }),
      (agenda) => setState(() {
        _loading = false;
        _agenda = agenda;
      }),
    );
  }

  Future<void> _openReference(AgendaReference reference) async {
    final raw = reference.kind == 'file'
        ? ApiEndpoints.fullUrlForPath(reference.url)
        : reference.url;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final title = _agenda?.label ?? _phases[_selectedPhase] ?? 'منهج الفرقة';
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
      ),
      body: Column(
        children: [
          if (_canBrowsePhases)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _phases.entries.map((entry) {
                    final selected = _selectedPhase == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        selectedColor: AppColors.primaryMaroon,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.accentWhite : AppColors.textPrimary,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedPhase = entry.key);
                          _load();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }
    final meetings = _agenda?.meetings ?? const [];
    if (_agenda?.phase == null && !_canBrowsePhases) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('لم يتم تحديد فرقتك بعد. اطلب من الخادم تحديد الفرقة.', textAlign: TextAlign.center),
        ),
      );
    }
    if (meetings.isEmpty) {
      return const Center(child: Text('لا يوجد منهج لهذه الفرقة بعد.'));
    }
    final subjects = _agenda?.subjects ?? const [];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length + (subjects.isEmpty ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (subjects.isNotEmpty && index == 0) return _materialsCard(subjects);
        final meeting = meetings[subjects.isEmpty ? index : index - 1];
        return _meetingCard(meeting);
      },
    );
  }

  Widget _materialsCard(List<AgendaSubject> subjects) {
    final hasMaterials = subjects.any((subject) =>
        subject.references.isNotEmpty ||
        subject.courses.any((course) => course.references.isNotEmpty));
    if (!hasMaterials) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المراجع', style: TextStyle(fontWeight: FontWeight.bold)),
          ...subjects.expand((subject) => [
                ...subject.references.map(
                  (reference) => _referenceTile(reference, subject.title),
                ),
                ...subject.courses.where((course) => course.references.isNotEmpty).expand(
                      (course) => course.references.map(
                        (reference) => _referenceTile(reference, '${subject.title} — ${course.title}'),
                      ),
                    ),
              ]),
        ],
      ),
    );
  }

  Widget _referenceTile(AgendaReference reference, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        reference.kind == 'file' ? Icons.picture_as_pdf : Icons.link,
        color: AppColors.primaryMaroon,
      ),
      title: Text(reference.title),
      subtitle: Text(subtitle),
      onTap: () => _openReference(reference),
    );
  }

  Widget _meetingCard(AgendaMeeting meeting) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meeting.date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (meeting.closed)
            Text(meeting.notes ?? 'لا يوجد خدمة', style: TextStyle(color: AppColors.textSecondary))
          else
            ...meeting.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subject, style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.w600)),
                      Text([
                        if (item.course != null && item.course!.isNotEmpty) item.course,
                        if (item.lectureLabel != null && item.lectureLabel!.isNotEmpty) item.lectureLabel,
                        item.topic,
                      ].whereType<String>().where((part) => part.isNotEmpty).join(' — ')),
                      ...item.references.map((reference) => TextButton(
                            onPressed: () => _openReference(reference),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerRight,
                            ),
                            child: Text(reference.title),
                          )),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
