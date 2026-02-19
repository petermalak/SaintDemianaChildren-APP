import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/shop/model/shop_gift_model.dart';
import 'package:saint_demiana_children/features/shop/model/shop_purchase_request_model.dart';
import 'package:saint_demiana_children/features/shop/repository/i_shop_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/model/class_model.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';

part 'khadem_shop_state.dart';

/// Cubit for khadem shop: classes with shop, gifts, purchase requests, approve/reject.
/// Depends on [IShopRepository] and [IClassRepository] (constructor injection).
class KhademShopCubit extends Cubit<KhademShopState> {
  KhademShopCubit(
    this._shopRepo,
    this._classRepo, {
    String? initialClassId,
    bool isSuperAdmin = false,
  })  : _initialClassId = initialClassId,
        _isSuperAdmin = isSuperAdmin,
        super(const KhademShopState());

  final IShopRepository _shopRepo;
  final IClassRepository _classRepo;
  final String? _initialClassId;
  final bool _isSuperAdmin;

  Future<void> loadClasses() async {
    emit(state.copyWith(loadingClasses: true));
    final result = _isSuperAdmin
        ? await _classRepo.loadClasses()
        : await _classRepo.loadMyClasses();
    result.fold(
      (fail) => emit(state.copyWith(
        classesWithShop: [],
        loadingClasses: false,
      )),
      (classes) {
        final withShop = classes.where((c) => c.hasShop).toList();
        String? selected = state.selectedClassId;
        if (selected == null && withShop.isNotEmpty) {
          selected = _initialClassId != null &&
                  withShop.any((c) => c.id == _initialClassId)
              ? _initialClassId
              : withShop.first.id;
        }
        emit(state.copyWith(
          classesWithShop: withShop,
          selectedClassId: selected,
          loadingClasses: false,
        ));
        if (selected != null) {
          loadGifts();
          loadRequests();
        }
      },
    );
  }

  void selectClass(String? classId) {
    emit(state.copyWith(selectedClassId: classId));
    if (classId != null) {
      loadGifts();
      loadRequests();
    }
  }

  Future<void> loadGifts() async {
    final classId = state.selectedClassId;
    if (classId == null) return;
    emit(state.copyWith(loadingGifts: true));
    final result = await _shopRepo.listGiftsForClass(classId);
    result.fold(
      (fail) => emit(state.copyWith(loadingGifts: false)),
      (list) => emit(state.copyWith(gifts: list, loadingGifts: false)),
    );
  }

  Future<void> loadRequests() async {
    final classId = state.selectedClassId;
    if (classId == null) return;
    emit(state.copyWith(loadingRequests: true));
    final result = await _shopRepo.listPurchaseRequestsForClass(classId);
    result.fold(
      (fail) => emit(state.copyWith(loadingRequests: false)),
      (list) => emit(state.copyWith(requests: list, loadingRequests: false)),
    );
  }

  Future<void> refresh() async {
    await loadClasses();
    if (state.selectedClassId != null) {
      loadGifts();
      loadRequests();
    }
  }

  Future<void> toggleVisibility(ShopGiftModel gift) async {
    final result = await _shopRepo.updateGift(gift.id, isVisible: !gift.isVisible);
    result.fold(
      (msg) => emit(state.copyWith(message: msg, messageIsError: true)),
      (_) {
        emit(state.copyWith(message: 'تم التحديث', messageIsError: false));
        loadGifts();
      },
    );
  }

  Future<void> deleteGift(ShopGiftModel gift) async {
    final result = await _shopRepo.deleteGift(gift.id);
    result.fold(
      (msg) => emit(state.copyWith(message: msg, messageIsError: true)),
      (_) {
        emit(state.copyWith(message: 'تم الحذف', messageIsError: false));
        loadGifts();
      },
    );
  }

  Future<void> approveRequest(ShopPurchaseRequestModel req) async {
    final result = await _shopRepo.approveRequest(req.id);
    result.fold(
      (msg) => emit(state.copyWith(message: msg, messageIsError: true)),
      (_) {
        emit(state.copyWith(message: 'تمت الموافقة على الطلب', messageIsError: false));
        loadRequests();
      },
    );
  }

  Future<void> rejectRequest(ShopPurchaseRequestModel req, {String? reason}) async {
    final result = await _shopRepo.rejectRequest(req.id, reason: reason);
    result.fold(
      (msg) => emit(state.copyWith(message: msg, messageIsError: true)),
      (_) {
        emit(state.copyWith(message: 'تم رفض الطلب', messageIsError: false));
        loadRequests();
      },
    );
  }

  void clearMessage() => emit(state.clearMessage());
}
