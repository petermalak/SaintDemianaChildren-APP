class AgendaReference {
  final String id;
  final String title;
  final String kind;
  final String url;

  const AgendaReference({
    required this.id,
    required this.title,
    required this.kind,
    required this.url,
  });

  factory AgendaReference.fromJson(Map<String, dynamic> json) {
    return AgendaReference(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'link',
      url: json['url']?.toString() ?? '',
    );
  }
}

class AgendaCourse {
  final String id;
  final String title;
  final List<AgendaReference> references;

  const AgendaCourse({
    required this.id,
    required this.title,
    required this.references,
  });

  factory AgendaCourse.fromJson(Map<String, dynamic> json) {
    final refs = (json['references'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaReference.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return AgendaCourse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      references: refs,
    );
  }
}

class AgendaSubject {
  final String id;
  final String title;
  final List<AgendaReference> references;
  final List<AgendaCourse> courses;

  const AgendaSubject({
    required this.id,
    required this.title,
    required this.references,
    this.courses = const [],
  });

  factory AgendaSubject.fromJson(Map<String, dynamic> json) {
    final refs = (json['references'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaReference.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final courses = (json['courses'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaCourse.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return AgendaSubject(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      references: refs,
      courses: courses,
    );
  }
}

class AgendaMeetingItem {
  final String subject;
  final String? course;
  final String? lectureLabel;
  final String? topic;
  final List<String> points;
  final List<AgendaReference> references;

  const AgendaMeetingItem({
    required this.subject,
    this.course,
    this.lectureLabel,
    this.topic,
    required this.points,
    this.references = const [],
  });

  factory AgendaMeetingItem.fromJson(Map<String, dynamic> json) {
    final references = (json['references'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaReference.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return AgendaMeetingItem(
      subject: json['subject']?.toString() ?? '',
      course: json['course']?.toString(),
      lectureLabel: json['lectureLabel']?.toString(),
      topic: json['topic']?.toString(),
      points: (json['points'] as List? ?? []).map((item) => item.toString()).toList(),
      references: references,
    );
  }
}

class AgendaMeeting {
  final String date;
  final bool closed;
  final String? notes;
  final List<AgendaMeetingItem> items;

  const AgendaMeeting({
    required this.date,
    required this.closed,
    this.notes,
    required this.items,
  });

  factory AgendaMeeting.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaMeetingItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return AgendaMeeting(
      date: json['date']?.toString() ?? '',
      closed: json['closed'] == true,
      notes: json['notes']?.toString(),
      items: items,
    );
  }
}

class PhaseAgenda {
  final int? phase;
  final String? label;
  final List<AgendaSubject> subjects;
  final List<AgendaMeeting> meetings;

  const PhaseAgenda({
    this.phase,
    this.label,
    required this.subjects,
    required this.meetings,
  });

  factory PhaseAgenda.fromJson(Map<String, dynamic> json) {
    final rawPhase = json['phase'];
    final phase = rawPhase is int ? rawPhase : int.tryParse('${rawPhase ?? ''}');
    final subjects = (json['subjects'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaSubject.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final meetings = (json['meetings'] as List? ?? [])
        .whereType<Map>()
        .map((item) => AgendaMeeting.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return PhaseAgenda(
      phase: phase,
      label: json['label']?.toString(),
      subjects: subjects,
      meetings: meetings,
    );
  }
}
