import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../core/services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService.instance;

  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get attendance records for a specific user
  List<AttendanceRecord> getAttendanceForUser(String userId) {
    return _attendanceRecords.where((record) => record.userId == userId).toList();
  }

  // Get attendance records by type
  List<AttendanceRecord> getAttendanceByType(AttendanceType type) {
    return _attendanceRecords.where((record) => record.type == type).toList();
  }

  // Get attendance records for a specific date
  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    return _attendanceRecords.where((record) {
      return record.date.year == date.year &&
             record.date.month == date.month &&
             record.date.day == date.day;
    }).toList();
  }

  // Get attendance statistics
  Map<AttendanceType, int> getAttendanceStats() {
    Map<AttendanceType, int> stats = {};
    for (AttendanceType type in AttendanceType.values) {
      stats[type] = _attendanceRecords.where((record) => record.type == type).length;
    }
    return stats;
  }

  // Get user attendance statistics
  Map<AttendanceType, int> getUserAttendanceStats(String userId) {
    Map<AttendanceType, int> stats = {};
    final userRecords = getAttendanceForUser(userId);
    for (AttendanceType type in AttendanceType.values) {
      stats[type] = userRecords.where((record) => record.type == type).length;
    }
    return stats;
  }

  // Add attendance record
  Future<bool> addAttendanceRecord({
    required String userId,
    required String userName,
    required AttendanceType type,
    required DateTime date,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.createAttendance({
        'userId': userId,
        'userName': userName,
        'type': type.toString().split('.').last,
        'date': date.toIso8601String().split('T')[0],
        'notes': notes,
      });

      final record = AttendanceRecord.fromJson(response);
      _attendanceRecords.add(record);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update attendance record
  Future<bool> updateAttendanceRecord(AttendanceRecord updatedRecord) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.updateAttendance(updatedRecord.id, {
        'userId': updatedRecord.userId,
        'userName': updatedRecord.userName,
        'type': updatedRecord.type.toString().split('.').last,
        'date': updatedRecord.date.toIso8601String().split('T')[0],
        'notes': updatedRecord.notes,
      });

      final updatedRecordFromApi = AttendanceRecord.fromJson(response);
      final index = _attendanceRecords.indexWhere((record) => record.id == updatedRecord.id);
      if (index != -1) {
        _attendanceRecords[index] = updatedRecordFromApi;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete attendance record
  Future<bool> deleteAttendanceRecord(String recordId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteAttendance(recordId);
      _attendanceRecords.removeWhere((record) => record.id == recordId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load attendance data from API
  Future<void> loadAttendanceData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getAttendance();
      _attendanceRecords = response.map((record) => AttendanceRecord.fromJson(record)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}