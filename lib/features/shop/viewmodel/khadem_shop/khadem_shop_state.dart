part of 'khadem_shop_cubit.dart';

@immutable
class KhademShopState {
  final List<ClassModel> classesWithShop;
  final String? selectedClassId;
  final List<ShopGiftModel> gifts;
  final List<ShopPurchaseRequestModel> requests;
  final bool loadingClasses;
  final bool loadingGifts;
  final bool loadingRequests;
  final String? message;
  final bool messageIsError;

  const KhademShopState({
    this.classesWithShop = const [],
    this.selectedClassId,
    this.gifts = const [],
    this.requests = const [],
    this.loadingClasses = true,
    this.loadingGifts = false,
    this.loadingRequests = false,
    this.message,
    this.messageIsError = false,
  });

  KhademShopState copyWith({
    List<ClassModel>? classesWithShop,
    String? selectedClassId,
    List<ShopGiftModel>? gifts,
    List<ShopPurchaseRequestModel>? requests,
    bool? loadingClasses,
    bool? loadingGifts,
    bool? loadingRequests,
    String? message,
    bool? messageIsError,
  }) {
    return KhademShopState(
      classesWithShop: classesWithShop ?? this.classesWithShop,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      gifts: gifts ?? this.gifts,
      requests: requests ?? this.requests,
      loadingClasses: loadingClasses ?? this.loadingClasses,
      loadingGifts: loadingGifts ?? this.loadingGifts,
      loadingRequests: loadingRequests ?? this.loadingRequests,
      message: message,
      messageIsError: messageIsError ?? this.messageIsError,
    );
  }

  KhademShopState clearMessage() => copyWith(message: null);
}
