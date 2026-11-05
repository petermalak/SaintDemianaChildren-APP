import 'package:equatable/equatable.dart';
import 'shop_gift_model.dart';

class ShopPurchaseRequestModel extends Equatable {
  final String id;
  final String giftId;
  final String userId;
  final String classId;
  final int scoreAmount;
  final String status; // pending, approved, rejected
  final String? processedBy;
  final DateTime? processedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final ShopGiftModel? gift;
  final ShopPurchaseRequestUser? user;
  final String? className;

  const ShopPurchaseRequestModel({
    required this.id,
    required this.giftId,
    required this.userId,
    required this.classId,
    required this.scoreAmount,
    required this.status,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
    this.createdAt,
    this.gift,
    this.user,
    this.className,
  });

  factory ShopPurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    ShopGiftModel? gift;
    if (json['gift'] is Map<String, dynamic>) {
      gift = ShopGiftModel.fromJson(json['gift'] as Map<String, dynamic>);
    }
    ShopPurchaseRequestUser? user;
    if (json['user'] is Map<String, dynamic>) {
      user = ShopPurchaseRequestUser.fromJson(json['user'] as Map<String, dynamic>);
    }
    return ShopPurchaseRequestModel(
      id: json['id']?.toString() ?? '',
      giftId: json['giftId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      scoreAmount: (json['scoreAmount'] is int) ? json['scoreAmount'] as int : int.tryParse(json['scoreAmount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      processedBy: json['processedBy']?.toString(),
      processedAt: json['processedAt'] != null ? DateTime.tryParse(json['processedAt'].toString()) : null,
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      gift: gift,
      user: user,
      className: json['class'] is Map ? (json['class'] as Map)['name']?.toString() : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [id, giftId, userId, status];
}

class ShopPurchaseRequestUser extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? profileImage;

  const ShopPurchaseRequestUser({
    required this.id,
    this.name,
    this.email,
    this.profileImage,
  });

  factory ShopPurchaseRequestUser.fromJson(Map<String, dynamic> json) {
    return ShopPurchaseRequestUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id];
}
