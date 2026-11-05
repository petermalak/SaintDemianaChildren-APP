import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../model/attendance_models.dart';
import '../../repository/i_pope_attendance_repository.dart';

class PopeCourseMarksScreen extends StatefulWidget {
  const PopeCourseMarksScreen({super.key});

  @override
  State<PopeCourseMarksScreen> createState() => _PopeCourseMarksScreenState();
}

class _PopeCourseMarksScreenState extends State<PopeCourseMarksScreen> {
  List<PopeCourseOption> _courses = const [];
  String? _courseId;
  String _lecture = '';
  String _status = '';
  String _search = '';
  CourseMarks? _marks;
  bool _loadingCourses = true;
  bool _loadingMarks = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final result = await sl<IPopeAttendanceRepository>().levelOneCourses();
    if (!mounted) return;
    result.fold(
      (message) => setState(() {
        _loadingCourses = false;
        _error = message;
      }),
      (courses) => setState(() {
        _loadingCourses = false;
        _courses = courses;
      }),
    );
  }

  Future<void> _loadMarks(String courseId) async {
    setState(() {
      _courseId = courseId;
      _lecture = '';
      _loadingMarks = true;
      _error = null;
      _marks = null;
    });
    final result = await sl<IPopeAttendanceRepository>().courseMarks(courseId);
    if (!mounted) return;
    result.fold(
      (message) => setState(() {
        _loadingMarks = false;
        _error = message;
      }),
      (marks) => setState(() {
        _loadingMarks = false;
        _marks = marks;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_marks?.marks ?? []).where((row) {
      if (_lecture.isNotEmpty && row.meetsOn != _lecture) return false;
      if (_status.isNotEmpty && row.status != _status) return false;
      final needle = _search.trim();
      if (needle.isEmpty) return true;
      return row.userName.contains(needle) || row.phoneNumber.contains(needle);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('سجل الفرقة الأولى'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: AppColors.accentWhite,
      ),
      body: _loadingCourses
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  decoration: const InputDecoration(
                    labelText: 'المادة',
                    border: OutlineInputBorder(),
                  ),
                  items: _courses
                      .map((course) => DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.subjectTitle} — ${course.title}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _loadMarks(value);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                if (_loadingMarks)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_marks != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_marks!.subjectTitle} — ${_marks!.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _marks!.lectures.map((lecture) {
                      final selected = _lecture == lecture.meetsOn;
                      return FilterChip(
                        label: Text('${lecture.meetsOn}\n${lecture.present} حضور · ${lecture.absent} غياب'),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _lecture = selected ? '' : lecture.meetsOn;
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '', label: Text('الكل')),
                      ButtonSegment(value: 'present', label: Text('حضور')),
                      ButtonSegment(value: 'absent', label: Text('غياب')),
                    ],
                    selected: {_status},
                    onSelectionChanged: (value) => setState(() => _status = value.first),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'الاسم أو الهاتف',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 8),
                  if (_marks!.marks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لم يُرفع حضور لهذه المادة بعد'),
                    )
                  else if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد علامات بهذا التصفية'),
                    )
                  else
                    ...rows.map((row) => Card(
                          child: ListTile(
                            title: Text(row.userName),
                            subtitle: Text([
                              if (row.group.isNotEmpty) row.group,
                              row.meetsOn,
                            ].join(' · ')),
                            trailing: Text(
                              row.status == 'present' ? 'حضور' : 'غياب',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: row.status == 'present' ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        )),
                ],
              ],
            ),
    );
  }
}
