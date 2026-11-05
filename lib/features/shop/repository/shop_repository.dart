import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import 'package:saint_demiana_children/core/services/sync_queue_service.dart';
import '../model/shop_gift_model.dart';
import '../model/shop_purchase_request_model.dart';
import 'i_shop_repository.dart';

class ShopRepository implements IShopRepository {
  final IApiService _apiService;

  ShopRepository(this._apiService);

  @override
  Future<Either<String, List<ShopGiftModel>>> listGiftsForClass(
    String classId, {
    bool visibleOnly = false,
  }) async {
    try {
      final path = ApiEndpoints.shopClassGifts(classId);
      final response = await _apiService.get(
        path: path,
        queryParameters: visibleOnly ? {'visibleOnly': 'true'} : null,
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) => ShopGiftModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Left('Failed to load gifts');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ShopGiftModel>>> getVisibleGiftsForClass(
    String classId,
  ) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.shopClassGiftsVisible(classId),
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) => ShopGiftModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Left('Failed to load gifts');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ShopGiftModel>> getGift(String giftId) async {
    try {
      final response =
          await _apiService.get(path: ApiEndpoints.shopGift(giftId));
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopGiftModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to load gift');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  static const List<String> _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  static String _ensureImageFileName(String name) {
    if (name.isEmpty) return 'image.jpg';
    final ext = name.split('.').last.toLowerCase();
    if (_imageExtensions.contains(ext)) return name;
    return '$name.jpg';
  }

  @override
  Future<Either<String, String>> uploadGiftImage(dynamic imageFile) async {
    try {
      final xFile = imageFile as XFile;
      final name = _ensureImageFileName(
          xFile.name.isNotEmpty ? xFile.name : 'image.jpg');
      final Response response;
      final path = xFile.path;
      // Web has no dart:io; always use bytes so MultipartFile.fromFile is never used.
      if (!kIsWeb && path.isNotEmpty) {
        response = await _apiService.postMultipart(
          path: ApiEndpoints.shopUploadGiftImage,
          filePath: path,
          fieldName: 'image',
          fileName: name,
        );
      } else {
        final bytes = await xFile.readAsBytes();
        response = await _apiService.postMultipart(
          path: ApiEndpoints.shopUploadGiftImage,
          fileBytes: bytes,
          fieldName: 'image',
          fileName: name,
        );
      }
      final data = response.data;
      if (data is Map && data['success'] == true && data['imageUrl'] != null) {
        return Right(data['imageUrl'] as String);
      }
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Failed to upload image';
      return Left(msg);
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('Upload failed: $e');
    }
  }

  @override
  Future<Either<String, ShopGiftModel>> createGift(
    String classId, {
    required String title,
    String? description,
    required int price,
    String? imageUrl,
    bool isVisible = true,
  }) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.shopClassGifts(classId),
        body: {
          'title': title,
          'description': description,
          'price': price,
          'imageUrl': imageUrl,
          'isVisible': isVisible,
        },
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopGiftModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to create gift');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ShopGiftModel>> updateGift(
    String giftId, {
    String? title,
    String? description,
    int? price,
    String? imageUrl,
    bool? isVisible,
    String? classId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (price != null) body['price'] = price;
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (isVisible != null) body['isVisible'] = isVisible;
      if (classId != null) body['classId'] = classId;
      final response = await _apiService.put(
        path: ApiEndpoints.shopGift(giftId),
        body: body,
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopGiftModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to update gift');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteGift(String giftId) async {
    try {
      final response = await _apiService.delete(
        path: ApiEndpoints.shopGift(giftId),
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true) {
        return const Right(null);
      }
      return const Left('Failed to delete gift');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ShopPurchaseRequestModel>> requestPurchase(
    String giftId,
  ) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.shopGiftRequestPurchase(giftId),
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopPurchaseRequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to submit request');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ShopPurchaseRequestModel>>> getMyPurchaseRequests({
    String? classId,
  }) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.shopMyPurchaseRequests,
        queryParameters: classId != null ? {'classId': classId} : null,
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) =>
                ShopPurchaseRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Left('Failed to load requests');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, List<ShopPurchaseRequestModel>>>
      listPurchaseRequestsForClass(
    String classId, {
    String? status,
  }) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.shopClassPurchaseRequests(classId),
        queryParameters: status != null ? {'status': status} : null,
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) =>
                ShopPurchaseRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Left('Failed to load requests');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ShopPurchaseRequestModel>> approveRequest(
    String requestId,
  ) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.shopApproveRequest(requestId),
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopPurchaseRequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to approve request');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, ShopPurchaseRequestModel>> rejectRequest(
    String requestId, {
    String? reason,
  }) async {
    try {
      final response = await _apiService.post(
        path: ApiEndpoints.shopRejectRequest(requestId),
        body: reason != null ? {'reason': reason} : null,
      );
      if (response.isQueued) return const Left(kQueuedOperationMessage);
      if (response.data['success'] == true && response.data['data'] != null) {
        return Right(
          ShopPurchaseRequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return const Left('Failed to reject request');
    } on DioException catch (e) {
      return Left(_apiService.handleError(e));
    } catch (e) {
      return Left('An unexpected error occurred: $e');
    }
  }
}
