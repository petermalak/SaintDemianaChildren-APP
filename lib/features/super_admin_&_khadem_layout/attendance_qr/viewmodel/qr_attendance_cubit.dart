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
    final result = await _membersRepository.fetchClassMembers(_classId);
    result.fold(
      (message) => emit(QrAttendanceRosterError(message)),
      (members) {
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
        ));
      },
    );
  }

  void clearFeedback() {
    final s = state;
    if (s is QrAttendanceReady && s.feedback != null) {
      emit(s.copyWith(clearFeedback: true));
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
        feedback: 'الرمز غير صالح (يجب أن يكون معرف المستخدم)',
      ));
      return;
    }

    final member = s.rosterById[trimmed];
    if (member == null) {
      emit(s.copyWith(
        feedback: 'هذا العضو غير موجود في الفصل المحدد',
      ));
      return;
    }

    if (s.scannedMembers.any((e) => e.id == trimmed)) {
      emit(s.copyWith(feedback: 'تم تسجيل هذا العضو مسبقاً'));
      return;
    }

    emit(s.copyWith(
      scannedMembers: [...s.scannedMembers, member],
      clearFeedback: true,
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
    emit(s.copyWith(scannedMembers: const []));
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
      emit(s.copyWith(feedback: 'يرجى اختيار نوع الاجتماع'));
      return;
    }
    if (s.scannedMembers.isEmpty) {
      emit(s.copyWith(feedback: 'لم يتم مسح أي عضو بعد'));
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
        emit(s.copyWith(isSubmitting: false, feedback: error));
      },
      (_) {
        emit(const QrAttendanceSubmitSuccess());
      },
    );
  }
}
