import 'package:equatable/equatable.dart';

class ShopGiftModel extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final int price;
  final String? imageUrl;
  final bool isVisible;
  final String createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShopGiftModel({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isVisible,
    required this.createdBy,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopGiftModel.fromJson(Map<String, dynamic> json) {
    return ShopGiftModel(
      id: json['id']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] is int) ? json['price'] as int : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      isVisible: json['isVisible'] == true,
      createdBy: json['createdBy']?.toString() ?? '',
      creatorName: json['creator']?['name']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isVisible': isVisible,
    };
  }

  @override
  List<Object?> get props => [id, classId, title, price, isVisible];
}
