import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../repository/i_program_repository.dart';

class ProgramQuizPage extends StatefulWidget {
  final String programId;
  final bool canPublish;

  const ProgramQuizPage({super.key, required this.programId, required this.canPublish});

  @override
  State<ProgramQuizPage> createState() => _ProgramQuizPageState();
}

class _ProgramQuizPageState extends State<ProgramQuizPage> {
  final _programs = sl<IProgramRepository>();
  final _title = TextEditingController();
  final _answers = <String, int>{};

  List<Map<String, dynamic>> _quizzes = const [];
  List<Map<String, dynamic>> _draft = const [];
  List<Map<String, dynamic>> _results = const [];
  Map<String, dynamic>? _open;
  DateTime? _opensAt;
  String? _editingId;
  bool _editing = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = _quizzes.isEmpty);
    final result = await _programs.quizzes(widget.programId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold((error) => _error = error, (data) {
        _error = null;
        _quizzes = _maps(data is Map ? data['quizzes'] : null);
      });
    });
  }

  Future<void> _openQuiz(Map<String, dynamic> quiz) async {
    final status = quiz['status']?.toString();
    if (!widget.canPublish && status == 'scheduled') {
      _toast('المسابقة لسه ما اتفتحتش');
      return;
    }
    if (!widget.canPublish && status == 'closed') {
      _toast('المسابقة قفلت');
      return;
    }
    setState(() => _busy = true);
    final result = await _programs.quiz(quiz['id'].toString());
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(_toast, (data) {
      if (data is! Map) return;
      final paper = Map<String, dynamic>.from(data);
      if (widget.canPublish || paper['manage'] == true) {
        _fillEditor(paper);
        return;
      }
      setState(() {
        _open = paper;
        _answers.clear();
      });
    });
  }

  void _fillEditor(Map<String, dynamic> paper) {
    _title.text = paper['title']?.toString() ?? '';
    setState(() {
      _editing = true;
      _editingId = paper['id']?.toString();
      _opensAt = DateTime.tryParse(paper['opensAt']?.toString() ?? '')?.toLocal();
      _draft = [
        for (final question in _maps(paper['questions']))
          {
            'chapter': question['chapter'],
            'prompt': question['prompt']?.toString() ?? '',
            'choices': _mapsOfChoices(question),
            'correctIndex': question['correctIndex'] is int
                ? question['correctIndex']
                : int.tryParse('${question['correctIndex']}') ?? 0,
          },
      ];
      _results = _maps(paper['results']);
      _open = null;
    });
  }

  void _startNew() {
    _title.clear();
    setState(() {
      _editing = true;
      _editingId = null;
      _opensAt = null;
      _draft = const [];
      _results = const [];
      _open = null;
    });
  }

  void _closeEditor() {
    setState(() {
      _editing = false;
      _editingId = null;
      _draft = const [];
      _results = const [];
    });
  }

  Future<void> _submit() async {
    final quiz = _open;
    if (quiz == null) return;
    final questions = _maps(quiz['questions']);
    if (questions.any((question) => !_answers.containsKey(question['id']?.toString()))) {
      _toast('جاوب على كل الأسئلة');
      return;
    }
    setState(() => _busy = true);
    final result = await _programs.submitQuiz(quiz['id'].toString(), Map<String, int>.from(_answers));
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(_toast, (data) {
      if (data is! Map) return;
      setState(() {
        _open = {
          ...quiz,
          'status': 'answered',
          'score': data['score'],
          'total': data['total'],
          'questions': data['questions'],
        };
      });
      _load();
    });
  }

  Future<void> _addQuestion({int? index}) async {
    final current = index == null ? null : _draft[index];
    final draft = await showDialog<_DraftQuestion>(
      context: context,
      builder: (context) => _QuestionDialog(
        prompt: current?['prompt']?.toString(),
        choices: current == null ? null : _mapsOfChoices(current),
        correctIndex: current?['correctIndex'] is int ? current!['correctIndex'] as int : 0,
      ),
    );
    if (draft == null || !mounted) return;
    final row = {
      'chapter': current?['chapter'],
      'prompt': draft.prompt,
      'choices': draft.choices,
      'correctIndex': draft.correctIndex,
    };
    setState(() {
      if (index == null) {
        _draft = [..._draft, row];
      } else {
        _draft = [..._draft]..[index] = row;
      }
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _draft.isEmpty) {
      _toast('اكتب اسم المسابقة وأضف سؤال');
      return;
    }
    setState(() => _busy = true);
    final editingId = _editingId;
    final result = editingId == null
        ? await _programs.createQuiz(widget.programId, title: _title.text.trim(), opensAt: _opensAt, questions: _draft)
        : await _programs.updateQuiz(editingId, title: _title.text.trim(), opensAt: _opensAt, questions: _draft);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(_toast, (data) {
      final cleared = data is Map && data['clearedAttempts'] == true;
      _closeEditor();
      _toast(cleared ? 'تم الحفظ، وإجابات الأولاد اتمسحت' : 'تم حفظ المسابقة');
      _load();
    });
  }

  Future<void> _delete() async {
    final quizId = _editingId;
    if (quizId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المسابقة'),
        content: const Text('المسابقة وإجابات الأولاد هتتمسح.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _programs.deleteQuiz(quizId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(_toast, (_) {
      _closeEditor();
      _toast('المسابقة اتحذفت');
      _load();
    });
  }

  Future<void> _pickOpenTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _opensAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_opensAt ?? DateTime.now()));
    if (time == null) return;
    setState(() => _opensAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
    }
    if (_error != null && _quizzes.isEmpty) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.textPrimary)));
    }
    if (_editing) return _editor();
    final quiz = _open;
    if (quiz != null) return _paper(quiz);
    return _list();
  }

  Widget _list() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.canPublish) ...[
          const Text('مسابقات الخدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('أمين الخدمة وخادم الفصل وخادم السكور ينزلوا المسابقة ويعدّلوها من هنا.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SubmitButton(text: 'مسابقة جديدة', onPressed: _busy ? () {} : _startNew),
          const SizedBox(height: 16),
        ],
        if (_quizzes.isEmpty) _empty('لسه مفيش مسابقة'),
        for (final quiz in _quizzes) ...[
          _card(
            title: quiz['title']?.toString() ?? '',
            subtitle: _quizSubtitle(quiz),
            trailing: widget.canPublish ? 'تعديل' : (quiz['status'] == 'answered' ? '${quiz['score']}/${quiz['total']}' : null),
            onTap: _busy ? null : () => _openQuiz(quiz),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _editor() {
    final when = _opensAt;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(onPressed: _closeEditor, icon: const Icon(Icons.arrow_forward, color: AppColors.primaryMaroon)),
                  Expanded(
                    child: Text(
                      _editingId == null ? 'مسابقة جديدة' : 'تعديل المسابقة',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              CustomTextField(controller: _title, labelText: 'اسم المسابقة'),
              const SizedBox(height: 12),
              _card(
                title: when == null ? 'تتفتح دلوقتي' : 'تتفتح ${when.day}/${when.month} ${when.hour}:${when.minute.toString().padLeft(2, '0')}',
                subtitle: 'اختار وقت الفتح',
                onTap: _pickOpenTime,
              ),
              const SizedBox(height: 8),
              Text('تعديل الأسئلة يمسح إجابات الأولاد.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              for (var index = 0; index < _draft.length; index++) ...[
                Row(
                  children: [
                    Expanded(
                      child: _card(
                        title: '${index + 1}. ${_draft[index]['prompt']}',
                        subtitle: '${_mapsOfChoices(_draft[index]).length} اختيارات',
                        onTap: _busy ? null : () => _addQuestion(index: index),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _draft = [..._draft]..removeAt(index)),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              SubmitButton(text: 'إضافة سؤال', onPressed: _busy ? () {} : () => _addQuestion()),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('مين حل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                for (final row in _results) ...[
                  _card(title: row['name']?.toString() ?? '', subtitle: '', trailing: '${row['score']}/${row['total']}'),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              SubmitButton(text: _editingId == null ? 'نزل المسابقة' : 'حفظ التعديل', onPressed: _busy ? () {} : _save),
              if (_editingId != null) ...[
                const SizedBox(height: 8),
                SubmitButton(
                  text: 'حذف المسابقة',
                  backgroundColor: AppColors.backgroundCard,
                  textColor: AppColors.primaryMaroon,
                  onPressed: _busy ? () {} : _delete,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _paper(Map<String, dynamic> quiz) {
    final questions = _maps(quiz['questions']);
    final review = questions.isNotEmpty && questions.first.containsKey('correctIndex');
    final scheduled = quiz['status'] == 'scheduled';
    String? chapter;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _open = null), icon: const Icon(Icons.arrow_forward, color: AppColors.primaryMaroon)),
                  Expanded(
                    child: Text(quiz['title']?.toString() ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                ],
              ),
              if (review)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('النتيجة ${quiz['score']} من ${quiz['total']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                ),
              if (scheduled)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('لسه ما اتفتحتش للأولاد', style: TextStyle(color: AppColors.primaryMaroon)),
                ),
              for (var index = 0; index < questions.length; index++) ...[
                if (questions[index]['chapter'] != null && questions[index]['chapter'] != chapter) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      () {
                        chapter = questions[index]['chapter']?.toString();
                        return chapter ?? '';
                      }(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                    ),
                  ),
                ],
                _question(index, questions[index], review || scheduled),
                const SizedBox(height: 12),
              ],
              if (_maps(quiz['results']).isNotEmpty) ...[
                const Text('مين حل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                for (final row in _maps(quiz['results'])) ...[
                  _card(title: row['name']?.toString() ?? '', subtitle: '', trailing: '${row['score']}/${row['total']}'),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        if (!review && !scheduled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SubmitButton(text: 'سلّم المسابقة', onPressed: _busy ? () {} : _submit),
          ),
      ],
    );
  }

  Widget _question(int index, Map<String, dynamic> question, bool locked) {
    final id = question['id']?.toString() ?? '$index';
    final choices = question['choices'] is List ? (question['choices'] as List).map((choice) => choice.toString()).toList() : <String>[];
    final correct = question['correctIndex'] is int ? question['correctIndex'] as int : int.tryParse('${question['correctIndex']}');
    final chosen = question['chosen'] is int ? question['chosen'] as int : _answers[id];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${question['prompt']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          for (var choice = 0; choice < choices.length; choice++)
            RadioListTile<int>(
              value: choice,
              groupValue: chosen,
              activeColor: correct == null ? AppColors.primaryMaroon : (choice == correct ? const Color(0xFF2E7D32) : AppColors.primaryMaroon),
              contentPadding: EdgeInsets.zero,
              title: Text(
                choices[choice],
                style: TextStyle(color: correct != null && choice == correct ? const Color(0xFF2E7D32) : AppColors.textPrimary),
              ),
              onChanged: locked ? null : (value) => setState(() => _answers[id] = value ?? choice),
            ),
        ],
      ),
    );
  }

  String _quizSubtitle(Map<String, dynamic> quiz) {
    final status = quiz['status']?.toString();
    final count = quiz['questionCount']?.toString() ?? '';
    final attempts = quiz['attemptCount'];
    final solved = attempts == null ? '' : ' · حلها $attempts';
    return switch (status) {
      'answered' => 'اتحلت$solved',
      'scheduled' => 'هتتفتح ${_format(quiz['opensAt'])}$solved',
      'closed' => 'قفلت$solved',
      _ => '$count سؤال$solved',
    };
  }

  String _format(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _card({required String title, required String subtitle, String? trailing, VoidCallback? onTap, VoidCallback? onTrailing}) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppColors.primaryMaroon),
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
                GestureDetector(
                  onTap: onTrailing ?? onTap,
                  child: Text(trailing, style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }
}

class _DraftQuestion {
  final String prompt;
  final List<String> choices;
  final int correctIndex;

  const _DraftQuestion(this.prompt, this.choices, this.correctIndex);
}

class _QuestionDialog extends StatefulWidget {
  final String? prompt;
  final List<String>? choices;
  final int correctIndex;

  const _QuestionDialog({this.prompt, this.choices, this.correctIndex = 0});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _prompt = TextEditingController();
  final _choices = List.generate(4, (_) => TextEditingController());
  late int _correct;

  @override
  void initState() {
    super.initState();
    _prompt.text = widget.prompt ?? '';
    final initial = widget.choices ?? const <String>[];
    for (var index = 0; index < _choices.length && index < initial.length; index++) {
      _choices[index].text = initial[index];
    }
    _correct = widget.correctIndex;
  }

  @override
  void dispose() {
    _prompt.dispose();
    for (final choice in _choices) {
      choice.dispose();
    }
    super.dispose();
  }

  void _save() {
    final choices = <String>[];
    var correct = 0;
    for (var index = 0; index < _choices.length; index++) {
      final text = _choices[index].text.trim();
      if (text.isEmpty) continue;
      if (index == _correct) correct = choices.length;
      choices.add(text);
    }
    if (_prompt.text.trim().isEmpty || choices.length < 2) return;
    Navigator.pop(context, _DraftQuestion(_prompt.text.trim(), choices, correct));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('سؤال'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: _prompt, labelText: 'السؤال'),
            for (var index = 0; index < _choices.length; index++) ...[
              const SizedBox(height: 8),
              RadioListTile<int>(
                value: index,
                groupValue: _correct,
                activeColor: AppColors.primaryMaroon,
                contentPadding: EdgeInsets.zero,
                title: CustomTextField(controller: _choices[index], labelText: 'اختيار ${index + 1}'),
                onChanged: (value) => setState(() => _correct = value ?? 0),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(onPressed: _save, child: Text(widget.prompt == null ? 'إضافة' : 'حفظ')),
      ],
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
}

List<String> _mapsOfChoices(Map<String, dynamic> question) {
  final choices = question['choices'];
  if (choices is! List) return const [];
  return choices.map((choice) => choice.toString()).toList();
}
