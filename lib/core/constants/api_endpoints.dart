class ApiEndpoints {
  static const String login = 'auth/login/';
  static String stats = "stats/";

  static const String members = 'classes/my-members/';
  static const String users = 'users/';

  static String attendance = "attendance";

  static const String logout = 'auth/logout/';
  static const String changePassword = 'auth/change-password/';

  // PRODUCTION - Your domain configuration
  // static const String baseUrl = "https://www.saint-demiana.com/api/";

  // DEVELOPMENT - Keep these commented for reference
  // static const String baseUrl = "http://localhost:7000/";
  static const String baseUrl = "http://192.168.1.11:7000/";
  // static const String baseUrl = "http://172.20.10.5:7000/";

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

  static String aftekadByWeek(String fridayDate) {
    return "eftekad/history/friday/$fridayDate";
  }

  // Scoring endpoints
  static const String scoring = "scoring/";
  static const String scoringConfig = "scoring/config/";
  static const String scoringTiers = "scoring/tiers/";
  static const String scoringTierById = "scoring/tiers/tier/";
  static const String scoringUsers = "scoring/users/";
  static const String scoringClasses = "scoring/classes/";
  static const String myScores = "scoring/my-scores";
  static const String myTransactions = "scoring/my-transactions";
}
