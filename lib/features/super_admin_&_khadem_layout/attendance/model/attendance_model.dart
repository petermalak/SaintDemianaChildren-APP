import 'package:equatable/equatable.dart';

class AttendanceModel extends Equatable {
  const AttendanceModel({this.attendanceRecords, this.attendanceDates});
  final List<String>? attendanceDates;
  final List<AttendanceRecord>? attendanceRecords;
  @override
  List<Object?> get props => [attendanceDates, attendanceRecords];

  factory AttendanceModel.fromJson(dynamic json) {
    // Handle if json is directly a list (array)
    List<AttendanceRecord> records;

    if (json is List) {
      // If the response is directly an array of records
      records = json
          .map((x) => AttendanceRecord.fromJson(x as Map<String, dynamic>))
          .toList();
    } else if (json is Map<String, dynamic>) {
      // If the response is an object with attendance_records key
      final recordsData = json["attendance_records"];
      if (recordsData == null) {
        records = [];
      } else {
        records = (recordsData as List)
            .map((x) => AttendanceRecord.fromJson(x as Map<String, dynamic>))
            .toList();
      }
    } else {
      // Fallback for unexpected format
      records = [];
    }

    // Extract unique dates from attendance records
    final dates = records
        .where((record) => record.date != null && record.date!.isNotEmpty)
        .map((record) => record.date!)
        .toSet()
        .toList();

    return AttendanceModel(
      attendanceDates: dates,
      attendanceRecords: records,
    );
  }
}

/// One person is one row. Attendance used to keep the name typed at the time,
/// so the same account showed twice when that spelling later changed.
List<AttendanceRecord> collapseAttendanceNames(List<AttendanceRecord> records) {
  final counts = <String, Map<String, int>>{};
  for (final record in records) {
    final id = record.userId;
    final name = record.userName;
    if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
    final byName = counts.putIfAbsent(id, () => {});
    byName[name] = (byName[name] ?? 0) + 1;
  }

  final canonical = <String, String>{};
  for (final entry in counts.entries) {
    var best = '';
    var bestCount = -1;
    entry.value.forEach((name, count) {
      if (count > bestCount || (count == bestCount && name.length > best.length)) {
        best = name;
        bestCount = count;
      }
    });
    canonical[entry.key] = best;
  }

  return records
      .map((record) {
        final name = canonical[record.userId];
        if (name == null || name == record.userName) return record;
        return AttendanceRecord(
          id: record.id,
          userId: record.userId,
          userName: name,
          date: record.date,
          type: record.type,
          notes: record.notes,
          shouldAddScore: record.shouldAddScore,
        );
      })
      .toList();
}

class AttendanceRecord {
  final String? id;
  final String? userId;
  final String? userName;
  final String? date;
  final String? type;
  final String? notes;
  final bool? shouldAddScore;

  AttendanceRecord({
    this.id,
    this.userId,
    this.userName,
    this.date,
    this.type,
    this.notes,
    this.shouldAddScore,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json["id"],
      userId: json["userId"],
      userName: json["userName"],
      date: json["date"],
      type: json["type"],
      notes: json["notes"],
      shouldAddScore: json.containsKey("shouldAddScore")
          ? _parseShouldAddScore(json["shouldAddScore"])
          : null,
    );
  }

  static bool? _parseShouldAddScore(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final lower = value.toString().toLowerCase().trim();
    if (lower.isEmpty) return null;
    if (['true', '1', 'yes', 'on'].contains(lower)) return true;
    if (['false', '0', 'no', 'off'].contains(lower)) return false;
    return null;
  }
}
