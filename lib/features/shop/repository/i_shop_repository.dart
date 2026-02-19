import 'package:dartz/dartz.dart';
import '../model/shop_gift_model.dart';
import '../model/shop_purchase_request_model.dart';

abstract class IShopRepository {
  /// List all gifts for a class (khadem: all; visibleOnly for filter)
  Future<Either<String, List<ShopGiftModel>>> listGiftsForClass(
    String classId, {
    bool visibleOnly = false,
  });

  /// List only visible gifts for a class (makhdoum)
  Future<Either<String, List<ShopGiftModel>>> getVisibleGiftsForClass(
    String classId,
  );

  /// Get single gift by id
  Future<Either<String, ShopGiftModel>> getGift(String giftId);

  /// Create gift (khadem)
  Future<Either<String, ShopGiftModel>> createGift(
    String classId, {
    required String title,
    String? description,
    required int price,
    String? imageUrl,
    bool isVisible = true,
  });

  /// Update gift (khadem). [classId] moves the gift to another class.
  Future<Either<String, ShopGiftModel>> updateGift(
    String giftId, {
    String? title,
    String? description,
    int? price,
    String? imageUrl,
    bool? isVisible,
    String? classId,
  });

  /// Delete gift (khadem)
  Future<Either<String, void>> deleteGift(String giftId);

  /// Upload gift image (khadem). Returns the image URL path to use in create/update gift.
  Future<Either<String, String>> uploadGiftImage(dynamic imageFile);

  /// Request to purchase a gift (makhdoum)
  Future<Either<String, ShopPurchaseRequestModel>> requestPurchase(
    String giftId,
  );

  /// My purchase requests
  Future<Either<String, List<ShopPurchaseRequestModel>>> getMyPurchaseRequests({
    String? classId,
  });

  /// List purchase requests for a class (khadem)
  Future<Either<String, List<ShopPurchaseRequestModel>>>
      listPurchaseRequestsForClass(
    String classId, {
    String? status,
  });

  /// Approve purchase request (khadem)
  Future<Either<String, ShopPurchaseRequestModel>> approveRequest(
    String requestId,
  );

  /// Reject purchase request (khadem)
  Future<Either<String, ShopPurchaseRequestModel>> rejectRequest(
    String requestId, {
    String? reason,
  });
}
