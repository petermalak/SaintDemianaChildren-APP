/// Date helper utilities for Friday-based week calculations
class DateHelper {
  /// Find the Friday date for the week that contains the given date
  /// The week runs from Friday to Thursday
  /// If the date is already a Friday, returns that date
  /// Otherwise, returns the most recent Friday before or on that date
  static DateTime getFridayForDate(DateTime date) {
    // Normalize to start of day
    final normalized = DateTime(date.year, date.month, date.day);
    
    // Get the day of week (1 = Monday, 7 = Sunday)
    // In Dart, DateTime.weekday returns 1-7 where 1=Monday, 7=Sunday
    // We need: Monday=1, Tuesday=2, ..., Friday=5, Saturday=6, Sunday=7
    final weekday = normalized.weekday;
    
    // Calculate days to subtract to get to Friday
    // If it's Friday (5), subtract 0
    // If it's Saturday (6), subtract 1
    // If it's Sunday (7), subtract 2
    // If it's Monday (1), subtract 3
    // If it's Tuesday (2), subtract 4
    // If it's Wednesday (3), subtract 5
    // If it's Thursday (4), subtract 6
    int daysToSubtract;
    if (weekday == DateTime.friday) {
      daysToSubtract = 0;
    } else if (weekday == DateTime.saturday) {
      daysToSubtract = 1;
    } else if (weekday == DateTime.sunday) {
      daysToSubtract = 2;
    } else {
      // Monday (1) through Thursday (4)
      // For Monday (1): need to subtract 3 = 1 + 2
      // For Tuesday (2): need to subtract 4 = 2 + 2
      // For Wednesday (3): need to subtract 5 = 3 + 2
      // For Thursday (4): need to subtract 6 = 4 + 2
      daysToSubtract = weekday + 2;
    }
    
    return normalized.subtract(Duration(days: daysToSubtract));
  }
  
  /// Format DateTime to YYYY-MM-DD string
  static String formatDateToString(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
  
  /// Get Friday date string (YYYY-MM-DD) for the week containing the given date
  static String getFridayDateStringForDate(DateTime date) {
    final friday = getFridayForDate(date);
    return formatDateToString(friday);
  }
}

