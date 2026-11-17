import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/interface/i_api_service.dart';
import 'i_program_repository.dart';

class ProgramRepository implements IProgramRepository {
  ProgramRepository(this._api);

  final IApiService _api;

  @override
  Future<Either<String, Map<String, dynamic>>> summary(String programId) async {
    final result = await _get(ApiEndpoints.programMe(programId));
    return result.fold(left, (data) => right(Map<String, dynamic>.from(data as Map)));
  }

  @override
  Future<Either<String, dynamic>> openSession(
    String programId, {
    required String classId,
    String? attendanceTypeId,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return _post(ApiEndpoints.programSessions(programId), {
      'classId': classId,
      'attendanceTypeId': attendanceTypeId,
      'startsAt': startsAt?.toUtc().toIso8601String(),
      'endsAt': endsAt?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<Either<String, dynamic>> closeSession(String sessionId) {
    return _post(ApiEndpoints.programSessionClose(sessionId), {});
  }

  @override
  Future<Either<String, dynamic>> manualScan(
    String programId, {
    required String classId,
    required String attendanceTypeId,
    required String userId,
    required String reason,
    DateTime? scannedAt,
  }) {
    return _post(ApiEndpoints.programScans(programId), {
      'classId': classId,
      'attendanceTypeId': attendanceTypeId,
      'userId': userId,
      'manual': true,
      'reason': reason,
      'scannedAt': (scannedAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
  }

  @override
  Future<Either<String, dynamic>> scanQr(
    String programId, {
    required String classId,
    required String attendanceTypeId,
    required String token,
    DateTime? scannedAt,
  }) {
    return _post(ApiEndpoints.programScans(programId), {
      'classId': classId,
      'attendanceTypeId': attendanceTypeId,
      'token': token,
      'manual': false,
      'scannedAt': (scannedAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
  }

  @override
  Future<Either<String, dynamic>> attendanceHistory(
    String programId, {
    required String classId,
    String? attendanceTypeId,
    required DateTime from,
    required DateTime to,
    String? query,
    bool? manual,
  }) {
    final trimmed = query?.trim() ?? '';
    return _request(() => _api.get(
          path: ApiEndpoints.programScans(programId),
          queryParameters: {
            'classId': classId,
            'from': _ymd(from),
            'to': _ymd(to),
            if (attendanceTypeId != null && attendanceTypeId.isNotEmpty) 'attendanceTypeId': attendanceTypeId,
            if (trimmed.isNotEmpty) 'q': trimmed,
            if (manual != null) 'manual': manual ? '1' : '0',
          },
        ));
  }

  @override
  Future<Either<String, dynamic>> freshQr(String programId) => _get(ApiEndpoints.programQr(programId));

  @override
  Future<Either<String, dynamic>> recordPoints(
    String programId, {
    required String ruleCode,
    required String classId,
    required String userId,
  }) {
    return _post(ApiEndpoints.programPoints(programId), {
      'ruleCode': ruleCode,
      'classId': classId,
      'userId': userId,
    });
  }

  @override
  Future<Either<String, dynamic>> requestCashout(String programId, int points) {
    return _post(ApiEndpoints.programCashout(programId), {'points': points});
  }

  @override
  Future<Either<String, dynamic>> markEftekad(
    String programId, {
    required String classId,
    required String userId,
    required String note,
  }) {
    return _post(ApiEndpoints.programEftekad(programId), {
      'classId': classId,
      'userId': userId,
      'note': note,
    });
  }

  @override
  Future<Either<String, dynamic>> classMembers(String programId, String classId) =>
      _get(ApiEndpoints.programClassMembers(programId, classId));

  @override
  Future<Either<String, dynamic>> setPointExemption(
    String programId, {
    required String userId,
    required bool exempt,
  }) {
    return _post(ApiEndpoints.programPointExemption(programId, userId), {'exempt': exempt});
  }

  @override
  Future<Either<String, dynamic>> createEvent(
    String programId, {
    required String title,
    required int price,
    DateTime? startsOn,
  }) {
    final date = startsOn == null
        ? null
        : '${startsOn.year.toString().padLeft(4, '0')}-${startsOn.month.toString().padLeft(2, '0')}-${startsOn.day.toString().padLeft(2, '0')}';
    return _post(ApiEndpoints.programEvents(programId), {
      'title': title,
      'price': price,
      'startsOn': date,
    });
  }

  @override
  Future<Either<String, dynamic>> bookEvent(
    String eventId, {
    required String userId,
    required int points,
  }) {
    return _post(ApiEndpoints.programEventBooking(eventId), {'userId': userId, 'points': points});
  }

  @override
  Future<Either<String, dynamic>> quizzes(String programId) => _get(ApiEndpoints.programQuizzes(programId));

  @override
  Future<Either<String, dynamic>> quiz(String quizId) => _get(ApiEndpoints.programQuiz(quizId));

  @override
  Future<Either<String, dynamic>> submitQuiz(String quizId, Map<String, int> answers) {
    return _post(ApiEndpoints.programQuizAnswers(quizId), {'answers': answers});
  }

  @override
  Future<Either<String, dynamic>> createQuiz(
    String programId, {
    required String title,
    DateTime? opensAt,
    required List<Map<String, dynamic>> questions,
  }) {
    return _post(ApiEndpoints.programQuizzes(programId), {
      'title': title,
      'opensAt': opensAt?.toUtc().toIso8601String(),
      'questions': questions,
    });
  }

  @override
  Future<Either<String, dynamic>> updateQuiz(
    String quizId, {
    required String title,
    DateTime? opensAt,
    required List<Map<String, dynamic>> questions,
  }) {
    return _request(() => _api.patch(path: ApiEndpoints.programQuiz(quizId), body: {
      'title': title,
      'opensAt': opensAt?.toUtc().toIso8601String(),
      'questions': questions,
    }));
  }

  @override
  Future<Either<String, dynamic>> deleteQuiz(String quizId) {
    return _request(() => _api.delete(path: ApiEndpoints.programQuiz(quizId)));
  }

  @override
  Future<Either<String, dynamic>> rankings(String programId) => _get(ApiEndpoints.programRankings(programId));

  @override
  Future<Either<String, dynamic>> budget(String programId) => _get(ApiEndpoints.programBudget(programId));

  @override
  Future<Either<String, dynamic>> cashouts(String programId) => _get(ApiEndpoints.programCashouts(programId));

  @override
  Future<Either<String, dynamic>> catalog(String programId) => _get(ApiEndpoints.programCatalog(programId));

  @override
  Future<Either<String, dynamic>> absences(String programId) => _get(ApiEndpoints.programAbsences(programId));

  @override
  Future<Either<String, dynamic>> yearClosePreview(String programId) =>
      _get(ApiEndpoints.programYearClosePreview(programId));

  @override
  Future<Either<String, dynamic>> carryOver(String programId) =>
      _post(ApiEndpoints.programCarryOver(programId), {});

  @override
  Future<Either<String, dynamic>> yearClose(String programId, String serviceYear) =>
      _post(ApiEndpoints.programYearClose(programId), {'serviceYear': serviceYear});

  @override
  Future<Either<String, dynamic>> myBookings(String programId) =>
      _get(ApiEndpoints.programBookings(programId));

  @override
  Future<Either<String, dynamic>> eventBookings(String eventId) =>
      _get(ApiEndpoints.programEventBookings(eventId));

  @override
  Future<Either<String, dynamic>> markCashPaid(String bookingId) =>
      _post(ApiEndpoints.programBookingCash(bookingId), {});

  @override
  Future<Either<String, dynamic>> refundBooking(String bookingId) =>
      _post(ApiEndpoints.programBookingRefund(bookingId), {});

  @override
  Future<Either<String, dynamic>> attendEvent(String eventId, {String? userId, String? token}) =>
      _post(ApiEndpoints.programEventAttendance(eventId), {
        'userId': userId,
        'token': token,
        'scannedAt': DateTime.now().toUtc().toIso8601String(),
      });

  @override
  Future<Either<String, dynamic>> reviewCashout(String id, {required bool approve}) =>
      _post(ApiEndpoints.programCashoutReview(id), {'approve': approve});

  @override
  Future<Either<String, dynamic>> setCashoutPaused(String programId, {required bool paused}) =>
      _post(ApiEndpoints.programCashoutPause(programId), {'paused': paused});

  @override
  Future<Either<String, dynamic>> saveSettings(String programId, Map<String, dynamic> settings) {
    return _request(() => _api.patch(path: ApiEndpoints.programSettings(programId), body: settings));
  }

  @override
  Future<Either<String, dynamic>> report(String programId) => _get(ApiEndpoints.programReport(programId));

  @override
  Future<Either<String, dynamic>> reverseLedger(String ledgerId) =>
      _post(ApiEndpoints.programLedgerReverse(ledgerId), {});

  @override
  Future<Either<String, dynamic>> eraseData(String programId, String confirmation) =>
      _post(ApiEndpoints.programErase(programId), {'confirmation': confirmation});

  @override
  Future<Either<String, dynamic>> deleteAccount(String confirmation) =>
      _post(ApiEndpoints.programDeleteAccount, {'confirmation': confirmation});

  @override
  Future<Either<String, dynamic>> saveProfileFields(String programId, Map<String, String> fields) {
    return _request(() => _api.patch(path: '${ApiEndpoints.programMe(programId)}/profile', body: {'fields': fields}));
  }

  Future<Either<String, dynamic>> _get(String path) => _request(() => _api.get(path: path));

  String _ymd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Either<String, dynamic>> _post(String path, Map<String, dynamic> body) {
    return _request(() => _api.post(path: path, body: body));
  }

  Future<Either<String, dynamic>> _request(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return right(response.data);
    } on DioException catch (error) {
      return left(_api.handleError(error));
    } catch (error) {
      return left(error.toString());
    }
  }
}
