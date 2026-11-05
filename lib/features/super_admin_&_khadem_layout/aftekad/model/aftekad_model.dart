enum AftekadType {
  phone_call,
  home_visit,
  whatsapp_message,
}

class AftekadModel {
  AftekadModel({
    this.id,
    this.khademId,
    this.makhdoumId,
    this.classId,
    this.type,
    this.status,
    this.duration,
    this.notes,
    this.scheduledDate,
    this.completedDate,
    this.priority,
    this.followUpRequired,
    this.followUpDate,
    this.createdAt,
    this.updatedAt,
    this.khadem,
    this.makhdoum,
    this.consecutiveMissedFridays,
    this.fridayAttendanceCount,
  });

  AftekadModel.fromJson(dynamic json) {
    id = json['id'];
    khademId = json['khademId'];
    makhdoumId = json['makhdoumId'];
    classId = json['classId'];
    type = json['type'] != null
        ? AftekadType.values.firstWhere((e) => e.name == json['type'])
        : null;
    // Handle both string "completed" and boolean true/false
    if (json['status'] == "completed" || json['status'] == true) {
      status = true;
    } else if (json['status'] == false || json['status'] == null) {
      status = false;
    } else {
      status = false;
    }
    duration = json['duration'];
    notes = json['notes'];
    scheduledDate = json['scheduledDate'];
    completedDate = json['completedDate'];
    priority = json['priority'];
    followUpRequired = json['followUpRequired'];
    followUpDate = json['followUpDate'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    khadem = json['khadem'] != null ? Khadem.fromJson(json['khadem']) : null;
    makhdoum =
        json['makhdoum'] != null ? Makhdoum.fromJson(json['makhdoum']) : null;
    consecutiveMissedFridays = json['consecutiveMissedFridays'] ?? 0;
    fridayAttendanceCount = json['fridayAttendanceCount'] ?? 0;
  }
  String? id;
  String? khademId;
  String? makhdoumId;
  String? classId;
  AftekadType? type;
  bool? status;
  dynamic duration;
  String? notes;
  String? scheduledDate;
  dynamic completedDate;
  String? priority;
  bool? followUpRequired;
  dynamic followUpDate;
  String? createdAt;
  String? updatedAt;
  Khadem? khadem;
  Makhdoum? makhdoum;
  int? consecutiveMissedFridays;
  int? fridayAttendanceCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['khademId'] = khademId;
    map['makhdoumId'] = makhdoumId;
    map['classId'] = classId;
    map['type'] = type;
    map['status'] = status;
    map['duration'] = duration;
    map['notes'] = notes;
    map['scheduledDate'] = scheduledDate;
    map['completedDate'] = completedDate;
    map['priority'] = priority;
    map['followUpRequired'] = followUpRequired;
    map['followUpDate'] = followUpDate;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    if (khadem != null) {
      map['khadem'] = khadem?.toJson();
    }
    if (makhdoum != null) {
      map['makhdoum'] = makhdoum?.toJson();
    }
    map['consecutiveMissedFridays'] = consecutiveMissedFridays;
    map['fridayAttendanceCount'] = fridayAttendanceCount;
    return map;
  }
}

class Makhdoum {
  Makhdoum({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
  });

  Makhdoum.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    role = json['role'];
  }
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
    map['phoneNumber'] = phoneNumber;
    map['role'] = role;
    return map;
  }
}

class Khadem {
  Khadem({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
  });

  Khadem.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    role = json['role'];
  }
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
    map['phoneNumber'] = phoneNumber;
    map['role'] = role;
    return map;
  }
}
