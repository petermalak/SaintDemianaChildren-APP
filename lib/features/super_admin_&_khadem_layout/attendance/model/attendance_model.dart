import 'package:equatable/equatable.dart';

class AttendanceModel extends Equatable {
  const AttendanceModel({this.attendance, this.attendanceDates});
  final List<String>? attendanceDates;
  final Map<String, Map<String, Map<String, bool>>>? attendance;
  @override
  List<Object?> get props => [attendanceDates];
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
        attendanceDates: List<String>.from(json['attendanceDates'] ?? []));
  }
}
