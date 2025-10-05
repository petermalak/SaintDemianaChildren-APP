class FeedModel {
  final String? id;
  final String? title;
  final String? description;
  final String? imageUrl;
  final DateTime? date;

  FeedModel({
    this.id,
    this.title,
    this.description,
    this.imageUrl,
    this.date,
  });
  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      date: DateTime.tryParse(json['date']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date?.toIso8601String(),
    };
  }
}
