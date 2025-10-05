enum AttendanceType {
  mass, // قداس
  specialMeeting, // اجتماع خاص
  generalMeeting, // اجتماع عام
  praise, // تسبحة
}

class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final AttendanceType type;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      type: AttendanceType.values.firstWhere(
        (e) => e.toString() == 'AttendanceType.${json['type']}',
        orElse: () => AttendanceType.mass,
      ),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    String? userName,
    AttendanceType? type,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension AttendanceTypeExtension on AttendanceType {
  String get displayName {
    switch (this) {
      case AttendanceType.mass:
        return 'قداس';
      case AttendanceType.specialMeeting:
        return 'اجتماع خاص';
      case AttendanceType.generalMeeting:
        return 'اجتماع عام';
      case AttendanceType.praise:
        return 'تسبحة';
    }
  }

  String get englishName {
    switch (this) {
      case AttendanceType.mass:
        return 'Mass';
      case AttendanceType.specialMeeting:
        return 'Special Meeting';
      case AttendanceType.generalMeeting:
        return 'General Meeting';
      case AttendanceType.praise:
        return 'Praise Service';
    }
  }

  String get icon {
    switch (this) {
      case AttendanceType.mass:
        return '⛪';
      case AttendanceType.specialMeeting:
        return '👥';
      case AttendanceType.generalMeeting:
        return '🏛️';
      case AttendanceType.praise:
        return '🎵';
    }
  }
}
