part of 'makhdoum_shop_cubit.dart';

@immutable
class MakhdoumShopState {
  final List<ShopGiftModel> gifts;
  final List<ShopPurchaseRequestModel> myRequests;
  final int? myScore;
  final bool loadingGifts;
  final bool loadingRequests;
  final bool loadingScore;
  final String? message;
  final bool messageIsError;

  const MakhdoumShopState({
    this.gifts = const [],
    this.myRequests = const [],
    this.myScore,
    this.loadingGifts = false,
    this.loadingRequests = false,
    this.loadingScore = false,
    this.message,
    this.messageIsError = false,
  });

  MakhdoumShopState copyWith({
    List<ShopGiftModel>? gifts,
    List<ShopPurchaseRequestModel>? myRequests,
    int? myScore,
    bool? loadingGifts,
    bool? loadingRequests,
    bool? loadingScore,
    String? message,
    bool? messageIsError,
  }) {
    return MakhdoumShopState(
      gifts: gifts ?? this.gifts,
      myRequests: myRequests ?? this.myRequests,
      myScore: myScore ?? this.myScore,
      loadingGifts: loadingGifts ?? this.loadingGifts,
      loadingRequests: loadingRequests ?? this.loadingRequests,
      loadingScore: loadingScore ?? this.loadingScore,
      message: message,
      messageIsError: messageIsError ?? this.messageIsError,
    );
  }

  MakhdoumShopState clearMessage() => copyWith(message: null);
}
