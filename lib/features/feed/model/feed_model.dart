class FeedModel {
  final String? id;
  final String? classId;
  final String? authorId;
  final String? type; // 'announcement', 'reminder', 'post', 'link'
  final String? title;
  final String? content;
  final String? link;
  final DateTime? eventDate;
  final bool? isPinned;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final FeedAuthor? author;
  final FeedClass? feedClass;

  FeedModel({
    this.id,
    this.classId,
    this.authorId,
    this.type,
    this.title,
    this.content,
    this.link,
    this.eventDate,
    this.isPinned,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.author,
    this.feedClass,
  });

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      id: json['id'],
      classId: json['classId'],
      authorId: json['authorId'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
      link: json['link'],
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'])
          : null,
      isPinned: json['isPinned'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      author:
          json['author'] != null ? FeedAuthor.fromJson(json['author']) : null,
      feedClass:
          json['class'] != null ? FeedClass.fromJson(json['class']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'authorId': authorId,
      'type': type,
      'title': title,
      'content': content,
      'link': link,
      'eventDate': eventDate?.toIso8601String(),
      'isPinned': isPinned,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'author': author?.toJson(),
      'class': feedClass?.toJson(),
    };
  }

  FeedModel copyWith({
    String? id,
    String? classId,
    String? authorId,
    String? type,
    String? title,
    String? content,
    String? link,
    DateTime? eventDate,
    bool? isPinned,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    FeedAuthor? author,
    FeedClass? feedClass,
  }) {
    return FeedModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      link: link ?? this.link,
      eventDate: eventDate ?? this.eventDate,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      feedClass: feedClass ?? this.feedClass,
    );
  }
}

class FeedAuthor {
  final String? id;
  final String? name;
  final String? profileImage;
  final String? role;

  FeedAuthor({
    this.id,
    this.name,
    this.profileImage,
    this.role,
  });

  factory FeedAuthor.fromJson(Map<String, dynamic> json) {
    return FeedAuthor(
      id: json['id'],
      name: json['name'],
      profileImage: json['profileImage'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'role': role,
    };
  }
}

class FeedClass {
  final String? id;
  final String? name;
  final String? description;

  FeedClass({
    this.id,
    this.name,
    this.description,
  });

  factory FeedClass.fromJson(Map<String, dynamic> json) {
    return FeedClass(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
