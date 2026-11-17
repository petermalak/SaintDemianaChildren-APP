class ApiEndpoints {
  static const String login = 'auth/login/';
  static String stats = "stats/";

  static const String members = 'classes/my-members/';
  static const String users = 'users/';
  static const String possibleDuplicates = 'users/possible-duplicates';
  static const String theaterDepartments = 'users/theater-departments';
  static String theaterProfile(String userId) => 'users/$userId/theater-profile';
  static const String userRequests = 'user-requests/';
  static String approveUserRequest(String id) => 'user-requests/$id/approve';
  static String rejectUserRequest(String id) => 'user-requests/$id/reject';

  static String attendance = "attendance";

  static const String logout = 'auth/logout/';
  static const String changePassword = 'auth/change-password/';

  // PRODUCTION - Your domain configuration
  static const String baseUrl = "https://www.saint-demiana.com/api/";
  // static const String baseUrl = "http://localhost:7000/";

  // DEVELOPMENT - Keep these commented for reference
//   static const String baseUrl = "http://localhost:7000/";
  // static const String baseUrl = "http://192.168.1.11:7000/";
  // static const String baseUrl = "http://172.20.10.5:7000/";
  // static const String baseUrl = "http://192.168.1.112:7000/";

  static const String feeds = "feeds/";
  static const String myFeeds = "feeds/my-feeds/";
  static const String myCreatedFeeds = "feeds/my-created/";
  static String feedsByClass(String classId) => "feeds/class/$classId";
  static String upcomingReminders(String classId) =>
      "feeds/class/$classId/reminders";
  static String feedById(String feedId) => "feeds/$feedId";
  static String togglePinFeed(String feedId) => "feeds/$feedId/pin";

  static const String myProfile = "users/me/";

  static const String bulkAddAttendance = "attendance/bulk/";
  static const String bulkUpdateAttendance = "attendance/bulk/";
  static const String bulkDeleteAttendance = "attendance/bulk/";

  static const String aftekad = "eftekad/";

  static const String classes = "classes/";
  static const String myClasses = "classes/my-classes/";
  static String classById(String classId) => "classes/$classId";
  static String classMembers(String classId) => "classes/$classId/members";
  static String classAssignments(String classId) =>
      "classes/$classId/assignments";

  static String aftekadByWeek(String fridayDate) {
    return "eftekad/history/friday/$fridayDate";
  }

  // Scoring endpoints
  static const String scoring = "scoring/";

  /// No trailing slash to avoid redirect on production (preserves Authorization header).
  static const String scoringConfig = "scoring/config";
  static const String scoringTiers = "scoring/tiers/";
  static const String scoringTierById = "scoring/tiers/tier/";
  static const String scoreDefinitions = "scoring/scores/definitions";
  static String scoreDefinitionById(String definitionId) =>
      "scoring/scores/definitions/$definitionId";
  static const String scoringUsers = "scoring/users/";
  static const String scoringClasses = "scoring/classes/";
  static String scoringClassScore(String classId) =>
      "scoring/classes/$classId/score";
  static const String myScores = "scoring/my-scores";
  static const String myTransactions = "scoring/my-transactions";

  // PopeAthnasius meeting data endpoints
  static String popeAthnasiusData(String userId) =>
      "users/$userId/pope-athnasius-data";
  static const String popeAgenda = "pope-athnasius/agenda";
  static const String popeAgendaMine = "pope-athnasius/agenda/mine";
  static const String popeMyCourse = "pope-athnasius/attendance/mine";
  static const String popeLevelOneCourses = "pope-athnasius/attendance/courses";
  static const String popeLevelTwoBoard = "pope-athnasius/attendance/level-two";
  static String popeCourseMarks(String courseId) =>
      "pope-athnasius/attendance/courses/$courseId/marks";

  // Shop (scoring shop) endpoints
  static const String shop = "shop/";
  static String shopClassGifts(String classId) => "shop/classes/$classId/gifts";
  static String shopClassGiftsVisible(String classId) =>
      "shop/classes/$classId/gifts/visible";
  static String shopGift(String giftId) => "shop/gifts/$giftId";
  static const String shopUploadGiftImage = "shop/gifts/upload-image";
  static String shopGiftRequestPurchase(String giftId) =>
      "shop/gifts/$giftId/request-purchase";
  static const String shopMyPurchaseRequests = "shop/my-purchase-requests";
  static String shopClassPurchaseRequests(String classId) =>
      "shop/classes/$classId/purchase-requests";
  static String shopApproveRequest(String requestId) =>
      "shop/purchase-requests/$requestId/approve";
  static String shopRejectRequest(String requestId) =>
      "shop/purchase-requests/$requestId/reject";

  static String programMe(String programId) => 'programs/$programId/me';
  static String programSessions(String programId) => 'programs/$programId/sessions';
  static String programScans(String programId) => 'programs/$programId/scans';
  static String programPoints(String programId) => 'programs/$programId/points';
  static String programCashout(String programId) => 'programs/$programId/cashout';
  static String programCashouts(String programId) => 'programs/$programId/cashouts';
  static String programEftekad(String programId) => 'programs/$programId/eftekad';
  static String programRankings(String programId) => 'programs/$programId/rankings';
  static String programBudget(String programId) => 'programs/$programId/budget';
  static String programCatalog(String programId) => 'programs/$programId/catalog';
  static String programClassMembers(String programId, String classId) =>
      'programs/$programId/classes/$classId/members';
  static String programPointExemption(String programId, String userId) =>
      'programs/$programId/members/$userId/point-exemption';
  static String programEvents(String programId) => 'programs/$programId/events';
  static String programEventBooking(String eventId) => 'programs/events/$eventId/bookings';
  static String programQuizzes(String programId) => 'programs/$programId/quizzes';
  static String programQuiz(String quizId) => 'programs/quizzes/$quizId';
  static String programQuizAnswers(String quizId) => 'programs/quizzes/$quizId/answers';
  static String programAbsences(String programId) => 'programs/$programId/absences';
  static String programYearClosePreview(String programId) =>
      'programs/$programId/year-close/preview';
  static String programYearClose(String programId) => 'programs/$programId/year-close';
  static String programCarryOver(String programId) => 'programs/$programId/carry-over';
  static String programQr(String programId) => 'programs/$programId/qr';
  static String programBookings(String programId) => 'programs/$programId/bookings';
  static String programTripLog(String programId) => 'programs/$programId/trip-log';
  static String programEventBookings(String eventId) => 'programs/events/$eventId/bookings';
  static String programBookingCash(String bookingId) => 'programs/bookings/$bookingId/cash';
  static String programBookingRefund(String bookingId) => 'programs/bookings/$bookingId/refund';
  static String programEventAttendance(String eventId) => 'programs/events/$eventId/attendance';
  static String programCashoutReview(String id) => 'programs/cashout/$id/review';
  static String programCashoutPause(String programId) => 'programs/$programId/cashout-pause';
  static String programSettings(String programId) => 'programs/$programId/settings';
  static String programReport(String programId) => 'programs/$programId/report';
  static String programLedgerReverse(String ledgerId) => 'programs/ledger/$ledgerId/reverse';
  static String programSessionClose(String sessionId) => 'programs/sessions/$sessionId/close';
  static String programErase(String programId) => 'programs/$programId/me/erase';
  static const String programDeleteAccount = 'programs/account/delete';

  /// App version config for force-update (public, no auth).
  static const String appVersion = 'app-version/';

  /// Returns full URL for a relative path (e.g. /uploads/shop-gifts/xxx).
  /// Use for Image.network when the API returns a path without origin.
  static String fullUrlForPath(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceFirst(RegExp(r'/$'), '');
    return base + (path.startsWith('/') ? path : '/$path');
  }
}
