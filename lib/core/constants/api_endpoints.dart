class ApiEndpoints {
  static const String login = 'auth/login/';
  static String stats = "stats/";

  static const String members = 'classes/my-members/';
  static const String users = 'users/';

  static String attendance = "attendance";

  static const String logout = 'auth/logout/';

  static const String baseUrl =
      "http://localhost:3000/api/";
  // "http://72.60.83.197:7000/";

  static const String feed = "feed/";

  static const String myProfile = "users/me/";

  static const String bulkAddAttendance = "attendance/bulk/";

  static const String aftekad = "eftekad/";

  static const String classes = "classes/";

  static String aftekadByWeek(String fridayDate) {
    return "eftekad/history/friday/$fridayDate";
  }
}
