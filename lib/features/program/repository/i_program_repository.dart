import 'package:dartz/dartz.dart';

abstract class IProgramRepository {
  Future<Either<String, Map<String, dynamic>>> summary(String programId);

  Future<Either<String, dynamic>> openSession(
    String programId, {
    required String classId,
    String? attendanceTypeId,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  Future<Either<String, dynamic>> closeSession(String sessionId);

  Future<Either<String, dynamic>> manualScan(
    String programId, {
    required String classId,
    required String attendanceTypeId,
    required String userId,
    required String reason,
    DateTime? scannedAt,
  });

  Future<Either<String, dynamic>> scanQr(
    String programId, {
    required String classId,
    required String attendanceTypeId,
    required String token,
    DateTime? scannedAt,
  });

  Future<Either<String, dynamic>> attendanceHistory(
    String programId, {
    required String classId,
    String? attendanceTypeId,
    required DateTime from,
    required DateTime to,
    String? query,
    bool? manual,
  });

  Future<Either<String, dynamic>> freshQr(String programId);

  Future<Either<String, dynamic>> recordPoints(
    String programId, {
    required String ruleCode,
    required String classId,
    required String userId,
  });

  Future<Either<String, dynamic>> requestCashout(String programId, int points);

  Future<Either<String, dynamic>> markEftekad(
    String programId, {
    required String classId,
    required String userId,
    required String note,
  });

  Future<Either<String, dynamic>> classMembers(String programId, String classId);

  Future<Either<String, dynamic>> setPointExemption(
    String programId, {
    required String userId,
    required bool exempt,
  });

  Future<Either<String, dynamic>> createEvent(
    String programId, {
    required String title,
    required int price,
    DateTime? startsOn,
  });

  Future<Either<String, dynamic>> bookEvent(
    String eventId, {
    required String userId,
    required int points,
  });

  Future<Either<String, dynamic>> quizzes(String programId);
  Future<Either<String, dynamic>> quiz(String quizId);
  Future<Either<String, dynamic>> submitQuiz(String quizId, Map<String, int> answers);
  Future<Either<String, dynamic>> createQuiz(
    String programId, {
    required String title,
    DateTime? opensAt,
    required List<Map<String, dynamic>> questions,
  });

  Future<Either<String, dynamic>> updateQuiz(
    String quizId, {
    required String title,
    DateTime? opensAt,
    required List<Map<String, dynamic>> questions,
  });

  Future<Either<String, dynamic>> deleteQuiz(String quizId);
  Future<Either<String, dynamic>> rankings(String programId);
  Future<Either<String, dynamic>> budget(String programId);
  Future<Either<String, dynamic>> cashouts(String programId);
  Future<Either<String, dynamic>> catalog(String programId);
  Future<Either<String, dynamic>> absences(String programId);
  Future<Either<String, dynamic>> yearClosePreview(String programId);
  Future<Either<String, dynamic>> carryOver(String programId);
  Future<Either<String, dynamic>> yearClose(String programId, String serviceYear);
  Future<Either<String, dynamic>> myBookings(String programId);
  Future<Either<String, dynamic>> eventBookings(String eventId);
  Future<Either<String, dynamic>> markCashPaid(String bookingId);
  Future<Either<String, dynamic>> refundBooking(String bookingId);
  Future<Either<String, dynamic>> attendEvent(String eventId, {String? userId, String? token});
  Future<Either<String, dynamic>> reviewCashout(String id, {required bool approve});
  Future<Either<String, dynamic>> setCashoutPaused(String programId, {required bool paused});
  Future<Either<String, dynamic>> saveSettings(String programId, Map<String, dynamic> settings);
  Future<Either<String, dynamic>> report(String programId);
  Future<Either<String, dynamic>> reverseLedger(String ledgerId);
  Future<Either<String, dynamic>> eraseData(String programId, String confirmation);
  Future<Either<String, dynamic>> deleteAccount(String confirmation);
  Future<Either<String, dynamic>> saveProfileFields(String programId, Map<String, String> fields);
}
