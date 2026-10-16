import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/model/user_model.dart';

class MeetingProfileSection extends StatelessWidget {
  const MeetingProfileSection({
    super.key,
    required this.meeting,
    this.viewOnly = false,
  });

  final PopeAthnasiusMeetingData meeting;
  final bool viewOnly;

  static const _levels = {
    1: 'الفرقة الأولى',
    2: 'الفرقة الثانية',
    3: 'الفرقة الثالثة',
    4: 'الفرقة الرابعة',
  };
  static const _groups = {
    1: 'الأسر',
    2: 'شباب وخريجين',
    3: 'إعدادي وثانوي',
  };
  static const _textFields = [
    ['code', 'الكود'],
    ['profession', 'الوظيفة'],
    ['meetingEmail', 'البريد'],
    ['maritalStatus', 'الحالة الاجتماعية'],
    ['regularChurch', 'الكنيسة المواظب عليها'],
    ['currentService', 'الخدمة الحالية'],
    ['yearsOfService', 'سنين الخدمة'],
    ['previousServices', 'خدمات سابقة'],
    ['registrationDate', 'تاريخ التسجيل'],
    ['previousCourses', 'دورات سابقة'],
    ['needToKnow', 'أريد أن أعرف'],
  ];
  static const _choices = [
    ['interestedBible', 'الكتاب المقدس'],
    ['interestedTheology', 'العقيدة'],
    ['interestedComparativeTheology', 'اللاهوت المقارن'],
    ['interestedApologetics', 'الدفاعيات'],
    ['interestedHistory', 'التاريخ'],
    ['interestedPatristics', 'آبائيات'],
    ['wantExam', 'يريد الامتحان'],
  ];

  @override
  Widget build(BuildContext context) {
    final extra = meeting.additionalData ?? const <String, dynamic>{};
    final filled = <Widget?>[
      _row('الفرقة', _levels[meeting.studyLevel]),
      _row('المرحلة', _groups[meeting.classPhase]),
      for (final field in _textFields) _row(field[1], _text(extra[field[0]])),
      for (final field in _choices) _row(field[1], _choice(extra[field[0]])),
    ].whereType<Widget>().toList();
    final empty = <String>[
      if (meeting.studyLevel == null) 'الفرقة',
      if (meeting.classPhase == null) 'المرحلة',
      for (final field in _textFields)
        if (_text(extra[field[0]]) == null) field[1],
      for (final field in _choices)
        if (_choice(extra[field[0]]) == null) field[1],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بيانات اللقاء',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
          ),
          if (viewOnly) ...[
            const SizedBox(height: 4),
            Text(
              'للعرض فقط، لا يمكن تعديلها',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          if (filled.isEmpty)
            Text('لم يُملأ ملف اللقاء بعد', style: TextStyle(color: AppColors.textSecondary))
          else
            ...filled,
          if (!viewOnly && empty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'لم يُملأ: ${empty.join('، ')}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _row(String label, String? value) {
    if (value == null || value.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _choice(dynamic value) {
    if (value == true || value == 1 || value == 'true' || value == 'yes') return 'نعم';
    if (value == false || value == 0 || value == 'false' || value == 'no') return 'لا';
    return null;
  }
}
