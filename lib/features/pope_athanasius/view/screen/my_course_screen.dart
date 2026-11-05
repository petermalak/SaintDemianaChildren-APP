import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../model/attendance_models.dart';
import '../../repository/i_pope_attendance_repository.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  MyRunningView? _view;
  bool _loading = true;
  String? _error;

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
    final result = await sl<IPopeAttendanceRepository>().myRunningCourses();
    if (!mounted) return;
    result.fold(
      (message) => setState(() {
        _loading = false;
        _error = message;
      }),
      (view) => setState(() {
        _loading = false;
        _view = view;
      }),
    );
  }

  String _dateLabel(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('d MMMM yyyy', 'ar').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('المادة الحالية'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    final courses = _view?.courses ?? const <MyRunningCourse>[];
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('لا توجد مادة جارية الآن.', textAlign: TextAlign.center),
        ),
      );
    }
    final showMarks = _view?.studyLevel == 1;
    return RefreshIndicator(
      color: AppColors.primaryMaroon,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'للعرض فقط',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...courses.map((course) => _courseCard(course, showMarks)),
        ],
      ),
    );
  }

  Widget _courseCard(MyRunningCourse course, bool showMarks) {
    final recorded = course.lectures.where((lecture) => lecture.status != null).length;
    final present = course.lectures.where((lecture) => lecture.status == 'present').length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.subjectTitle, style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(course.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${_dateLabel(course.startsOn)} — ${_dateLabel(course.endsOn)}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (showMarks) ...[
            const SizedBox(height: 8),
            Text('حضورك: $present من $recorded محاضرة مسجلة'),
          ],
          const SizedBox(height: 12),
          ...course.lectures.map((lecture) => _lectureRow(lecture, showMarks)),
        ],
      ),
    );
  }

  Widget _lectureRow(MyLecture lecture, bool showMarks) {
    final title = [
      if (lecture.lectureLabel.isNotEmpty) lecture.lectureLabel,
      if (lecture.topic.isNotEmpty) lecture.topic,
    ].join(' — ');
    final status = switch (lecture.status) {
      'present' => 'حضور',
      'absent' => 'غياب',
      _ => 'لم يُسجل',
    };
    final statusColor = switch (lecture.status) {
      'present' => Colors.green.shade700,
      'absent' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(lecture.meetsOn), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (title.isNotEmpty)
                  Text(title, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (showMarks)
            Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
