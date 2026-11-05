import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/scoring/repository/i_scoring_repository.dart';
import 'package:saint_demiana_children/features/shop/model/shop_gift_model.dart';
import 'package:saint_demiana_children/features/shop/model/shop_purchase_request_model.dart';
import 'package:saint_demiana_children/features/shop/repository/i_shop_repository.dart';

part 'makhdoum_shop_state.dart';

/// Cubit for makhdoum shop: gifts list, my requests, my score, request purchase.
/// Depends on [IShopRepository], [IScoringRepository], [IProfileRepository] (constructor injection).
class MakhdoumShopCubit extends Cubit<MakhdoumShopState> {
  MakhdoumShopCubit(
    this._classId,
    this._shopRepo,
    this._scoringRepo,
    this._profileRepo,
  ) : super(const MakhdoumShopState());

  final String _classId;
  final IShopRepository _shopRepo;
  final IScoringRepository _scoringRepo;
  final IProfileRepository _profileRepo;

  Future<void> loadGifts() async {
    emit(state.copyWith(loadingGifts: true));
    final result = await _shopRepo.getVisibleGiftsForClass(_classId);
    result.fold(
      (fail) => emit(state.copyWith(
        loadingGifts: false,
        message: fail,
        messageIsError: true,
      )),
      (list) => emit(state.copyWith(
        gifts: list,
        loadingGifts: false,
      )),
    );
  }

  Future<void> loadMyRequests() async {
    emit(state.copyWith(loadingRequests: true));
    final result = await _shopRepo.getMyPurchaseRequests(classId: _classId);
    result.fold(
      (fail) => emit(state.copyWith(
        loadingRequests: false,
        message: fail,
        messageIsError: true,
      )),
      (list) => emit(state.copyWith(
        myRequests: list,
        loadingRequests: false,
      )),
    );
  }

  Future<void> loadMyScore() async {
    final user = _profileRepo.user;
    if (user?.id == null) return;
    emit(state.copyWith(loadingScore: true));
    final result = await _scoringRepo.getUserScore(user!.id!, _classId);
    result.fold(
      (fail) => emit(state.copyWith(loadingScore: false)),
      (score) => emit(state.copyWith(
        myScore: score.totalPoints,
        loadingScore: false,
      )),
    );
  }

  /// Load all data (gifts, requests, score).
  Future<void> refresh() async {
    loadGifts();
    loadMyRequests();
    loadMyScore();
  }

  /// Request to purchase a gift. Emits message on success or error.
  Future<void> requestPurchase(ShopGiftModel gift) async {
    final result = await _shopRepo.requestPurchase(gift.id);
    result.fold(
      (msg) => emit(state.copyWith(message: msg, messageIsError: true)),
      (_) {
        emit(state.copyWith(
          message: 'تم إرسال الطلب. في انتظار موافقة الخادم.',
          messageIsError: false,
        ));
        loadMyRequests();
        loadMyScore();
      },
    );
  }

  void clearMessage() => emit(state.clearMessage());
}
