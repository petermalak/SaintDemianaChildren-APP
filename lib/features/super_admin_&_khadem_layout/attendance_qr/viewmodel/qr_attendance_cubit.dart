import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/model/user_model.dart';
import '../../attendance/repository/i_attendance_repository.dart';
import '../../members/repository/i_members_repository.dart';
import 'qr_attendance_state.dart';

class QrAttendanceCubit extends Cubit<QrAttendanceState> {
  QrAttendanceCubit(
    this._membersRepository,
    this._attendanceRepository,
    this._classId,
  ) : super(const QrAttendanceLoadingRoster());

  final IMembersRepository _membersRepository;
  final IAttendanceRepository _attendanceRepository;
  final String _classId;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<void> loadRoster() async {
    emit(const QrAttendanceLoadingRoster());
    final result =
        await _membersRepository.fetchClassMembers(_classId, summary: true);
    result.fold(
      (message) {
        // Last-chance offline: global members list from splash / members tab.
        final fallback = _membersRepository.members
            .where(_memberLikelyInThisClass)
            .toList();
        if (fallback.isEmpty) {
          emit(QrAttendanceRosterError(message));
          return;
        }
        _emitReadyFrom(fallback);
      },
      _emitReadyFrom,
    );
  }

  bool _isClassServant(UserModel member) {
    return member.classes.any((info) =>
        info.classId == _classId &&
        info.membershipRole == 'khadem' &&
        info.isActive != false);
  }

  bool _memberLikelyInThisClass(UserModel m) {
    if (m.classId == _classId) return true;
    if (m.classes.any((c) => c.classId == _classId)) return true;
    if (m.classIds?.contains(_classId) == true) return true;
    // Summary member lists sometimes omit class ids but include Pope meeting data.
    if (m.isPopeAthnasius == true) return true;
    if (m.popeAthnasiusMeetingData != null) return true;
    return false;
  }

  void _emitReadyFrom(List<UserModel> members) {
    final map = <String, UserModel>{};
    for (final m in members) {
      final id = m.id;
      if (id != null && id.isNotEmpty) {
        map[id] = m;
      }
    }
    emit(QrAttendanceReady(
      rosterById: map,
      scannedMembers: const [],
      selectedDate: DateTime.now(),
      selectedEvent: 'generalMeeting',
    ));
  }

  void clearFeedback() {
    final s = state;
    if (s is QrAttendanceReady && s.feedback != null) {
      emit(s.copyWith(clearFeedback: true));
    }
  }

  void clearLastSuccess() {
    final s = state;
    if (s is QrAttendanceReady && s.lastSuccessName != null) {
      emit(s.copyWith(clearLastSuccessName: true));
    }
  }

  void setSelectedEvent(String? value) {
    final s = state;
    if (s is! QrAttendanceReady) return;
    emit(s.copyWith(selectedEvent: value, clearSelectedEvent: value == null));
  }

  void setSelectedDate(DateTime date) {
    final s = state;
    if (s is! QrAttendanceReady) return;
    emit(s.copyWith(selectedDate: date));
  }

  void setShouldAddScore(bool value) {
    final s = state;
    if (s is! QrAttendanceReady) return;
    emit(s.copyWith(shouldAddScore: value));
  }

  /// Validates [raw] as UUID, roster membership, duplicate; emits feedback.
  void tryAddScan(String raw) {
    final s = state;
    if (s is! QrAttendanceReady) return;

    final trimmed = raw.trim();
    if (!_uuidRegex.hasMatch(trimmed)) {
      emit(s.copyWith(
        feedback: 'الرمز غير صالح — امسح بطاقة الفرقة الثانية',
        feedbackIsError: true,
      ));
      return;
    }

    final member = s.rosterById[trimmed];
    if (member == null) {
      emit(s.copyWith(
        feedback: 'هذا العضو غير موجود في فصل البابا أثناسيوس',
        feedbackIsError: true,
      ));
      return;
    }

    if (member.popeAthnasiusMeetingData?.studyLevel != 2 && !_isClassServant(member)) {
      emit(s.copyWith(
        feedback: 'هذه البطاقة ليست من الفرقة الثانية. الفرقة الأولى حضورها على الورق',
        feedbackIsError: true,
      ));
      return;
    }

    if (s.scannedMembers.any((e) => e.id == trimmed)) {
      emit(s.copyWith(
        feedback: 'تم تسجيل ${member.name ?? 'هذا العضو'} مسبقاً في هذه الجلسة',
        feedbackIsError: true,
      ));
      return;
    }

    final name = member.name?.trim().isNotEmpty == true ? member.name!.trim() : 'عضو';
    emit(s.copyWith(
      scannedMembers: [...s.scannedMembers, member],
      clearFeedback: true,
      lastSuccessName: name,
      successTick: s.successTick + 1,
      feedback: 'تم إضافة $name',
      feedbackIsError: false,
    ));
  }

  void removeMember(String userId) {
    final s = state;
    if (s is! QrAttendanceReady) return;
    emit(s.copyWith(
      scannedMembers:
          s.scannedMembers.where((e) => e.id != userId).toList(),
    ));
  }

  void clearAllScans() {
    final s = state;
    if (s is! QrAttendanceReady) return;
    emit(s.copyWith(scannedMembers: const [], clearLastSuccessName: true));
  }

  void removeLastScan() {
    final s = state;
    if (s is! QrAttendanceReady || s.scannedMembers.isEmpty) return;
    emit(s.copyWith(
      scannedMembers:
          s.scannedMembers.sublist(0, s.scannedMembers.length - 1),
    ));
  }

  /// Manual add by pasted id (same validation as scan).
  void tryAddManualId(String raw) {
    tryAddScan(raw);
  }

  Future<void> submit() async {
    final s = state;
    if (s is! QrAttendanceReady) return;

    if (s.selectedEvent == null || s.selectedEvent!.isEmpty) {
      emit(s.copyWith(feedback: 'يرجى اختيار نوع الاجتماع', feedbackIsError: true));
      return;
    }
    if (s.scannedMembers.isEmpty) {
      emit(s.copyWith(feedback: 'لم يتم مسح أي عضو بعد', feedbackIsError: true));
      return;
    }

    emit(s.copyWith(isSubmitting: true, clearFeedback: true));

    final result = await _attendanceRepository.bulkAddAttendance(
      members: s.scannedMembers,
      event: s.selectedEvent!,
      date: s.selectedDate,
      addScore: s.shouldAddScore,
    );

    result.fold(
      (error) {
        emit(s.copyWith(isSubmitting: false, feedback: error, feedbackIsError: true));
      },
      (_) {
        emit(const QrAttendanceSubmitSuccess());
      },
    );
  }
}
