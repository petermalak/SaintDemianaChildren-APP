class LevelTwoPerson {
  final String id;
  final String name;
  final String phoneNumber;
  final String group;
  final bool bible;
  final bool doctrine;

  const LevelTwoPerson({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.group,
    required this.bible,
    required this.doctrine,
  });

  factory LevelTwoPerson.fromJson(Map<String, dynamic> json) {
    return LevelTwoPerson(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      bible: json['bible'] == true,
      doctrine: json['doctrine'] == true,
    );
  }
}

class LevelTwoBoard {
  final String date;
  final int total;
  final int biblePresent;
  final int doctrinePresent;
  final List<LevelTwoPerson> people;

  const LevelTwoBoard({
    required this.date,
    required this.total,
    required this.biblePresent,
    required this.doctrinePresent,
    required this.people,
  });

  factory LevelTwoBoard.fromJson(Map<String, dynamic> json) {
    final people = (json['people'] as List? ?? [])
        .whereType<Map>()
        .map((item) => LevelTwoPerson.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return LevelTwoBoard(
      date: json['date']?.toString() ?? '',
      total: json['total'] is num ? (json['total'] as num).toInt() : people.length,
      biblePresent: json['biblePresent'] is num ? (json['biblePresent'] as num).toInt() : 0,
      doctrinePresent: json['doctrinePresent'] is num ? (json['doctrinePresent'] as num).toInt() : 0,
      people: people,
    );
  }
}

class PopeCourseOption {
  final String id;
  final String title;
  final String subjectTitle;

  const PopeCourseOption({
    required this.id,
    required this.title,
    required this.subjectTitle,
  });

  factory PopeCourseOption.fromJson(Map<String, dynamic> json) {
    return PopeCourseOption(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subjectTitle: json['subjectTitle']?.toString() ?? '',
    );
  }
}

class CourseLectureSummary {
  final String meetsOn;
  final int present;
  final int absent;

  const CourseLectureSummary({
    required this.meetsOn,
    required this.present,
    required this.absent,
  });

  factory CourseLectureSummary.fromJson(Map<String, dynamic> json) {
    int read(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    return CourseLectureSummary(
      meetsOn: json['meetsOn']?.toString() ?? '',
      present: read(json['present']),
      absent: read(json['absent']),
    );
  }
}

class CourseMark {
  final String id;
  final String userName;
  final String phoneNumber;
  final String group;
  final String meetsOn;
  final String status;

  const CourseMark({
    required this.id,
    required this.userName,
    required this.phoneNumber,
    required this.group,
    required this.meetsOn,
    required this.status,
  });

  factory CourseMark.fromJson(Map<String, dynamic> json) {
    return CourseMark(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      meetsOn: json['meetsOn']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MyLecture {
  final String meetsOn;
  final String topic;
  final String lectureLabel;
  final String? status;

  const MyLecture({
    required this.meetsOn,
    required this.topic,
    required this.lectureLabel,
    this.status,
  });

  factory MyLecture.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    return MyLecture(
      meetsOn: json['meetsOn']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      lectureLabel: json['lectureLabel']?.toString() ?? '',
      status: status == null || status.isEmpty ? null : status,
    );
  }
}

class MyRunningCourse {
  final String id;
  final String title;
  final String subjectTitle;
  final String startsOn;
  final String endsOn;
  final List<MyLecture> lectures;

  const MyRunningCourse({
    required this.id,
    required this.title,
    required this.subjectTitle,
    required this.startsOn,
    required this.endsOn,
    required this.lectures,
  });

  factory MyRunningCourse.fromJson(Map<String, dynamic> json) {
    return MyRunningCourse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subjectTitle: json['subjectTitle']?.toString() ?? '',
      startsOn: json['startsOn']?.toString() ?? '',
      endsOn: json['endsOn']?.toString() ?? '',
      lectures: (json['lectures'] as List? ?? [])
          .whereType<Map>()
          .map((item) => MyLecture.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class MyRunningView {
  final int? studyLevel;
  final String today;
  final List<MyRunningCourse> courses;

  const MyRunningView({
    required this.studyLevel,
    required this.today,
    required this.courses,
  });

  factory MyRunningView.fromJson(Map<String, dynamic> json) {
    final rawLevel = json['studyLevel'];
    return MyRunningView(
      studyLevel: rawLevel is int ? rawLevel : int.tryParse('${rawLevel ?? ''}'),
      today: json['today']?.toString() ?? '',
      courses: (json['courses'] as List? ?? [])
          .whereType<Map>()
          .map((item) => MyRunningCourse.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class CourseMarks {
  final String title;
  final String subjectTitle;
  final List<CourseLectureSummary> lectures;
  final List<CourseMark> marks;

  const CourseMarks({
    required this.title,
    required this.subjectTitle,
    required this.lectures,
    required this.marks,
  });

  factory CourseMarks.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) map) {
      return (json[key] as List? ?? [])
          .whereType<Map>()
          .map((item) => map(Map<String, dynamic>.from(item)))
          .toList();
    }

    return CourseMarks(
      title: json['title']?.toString() ?? '',
      subjectTitle: json['subjectTitle']?.toString() ?? '',
      lectures: readList('lectures', CourseLectureSummary.fromJson),
      marks: readList('marks', CourseMark.fromJson),
    );
  }
}
