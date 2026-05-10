class ApiEndpoints {
  static const String login = 'auth/login/';
  static String stats = "stats/";

  static const String members = 'classes/my-members/';
  static const String users = 'users/';

  static String attendance = "attendance";

  static const String logout = 'auth/logout/';
  static const String changePassword = 'auth/change-password/';

  // PRODUCTION - Your domain configuration
  static const String baseUrl = "https://www.saint-demiana.com/api/";

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
