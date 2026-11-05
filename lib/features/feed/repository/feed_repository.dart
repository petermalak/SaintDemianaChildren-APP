import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';
import '../../../core/services/interface/i_api_service.dart';
import 'i_feed_repository.dart';

class FeedRepository implements IFeedRepository {
  final IApiService _apiService;
  FeedRepository(this._apiService);
  List<FeedModel>? _cachedFeeds;

  @override
  Future<Either<String, List<FeedModel>>> getMyFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        path: ApiEndpoints.myFeeds,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final feedsList = (response.data['data']['feeds'] as List)
            .map((e) => FeedModel.fromJson(e))
            .toList();

        if (offset == 0) {
          _cachedFeeds = feedsList;
        } else {
          _cachedFeeds?.addAll(feedsList);
        }

        return right(feedsList);
      } else {
        return left(response.data['message'] ?? 'Failed to fetch feeds');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, List<FeedModel>>> getFeedsByClass(
    String classId, {
    String? type,
    int limit = 50,
    int offset = 0,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'includeInactive': includeInactive.toString(),
      };
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        path: ApiEndpoints.feedsByClass(classId),
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final feedsList = (response.data['data']['feeds'] as List)
            .map((e) => FeedModel.fromJson(e))
            .toList();
        return right(feedsList);
      } else {
        return left(response.data['message'] ?? 'Failed to fetch feeds');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, FeedModel>> getFeedById(String feedId) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.feedById(feedId),
      );

      if (response.data['success'] == true) {
        final feed = FeedModel.fromJson(response.data['data']);
        return right(feed);
      } else {
        return left(response.data['message'] ?? 'Failed to fetch feed');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, FeedModel>> createFeed({
    required String classId,
    required String type,
    required String title,
    required String content,
    String? link,
    DateTime? eventDate,
    bool isPinned = false,
  }) async {
    try {
      final body = {
        'classId': classId,
        'type': type,
        'title': title,
        'content': content,
        'link': link,
        'eventDate': eventDate?.toIso8601String(),
        'isPinned': isPinned,
      };

      final response = await _apiService.post(
        path: ApiEndpoints.feeds,
        body: body,
      );

      if (response.data['success'] == true) {
        final feed = FeedModel.fromJson(response.data['data']);
        _cachedFeeds?.insert(0, feed);
        return right(feed);
      } else {
        return left(response.data['message'] ?? 'Failed to create feed');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, FeedModel>> updateFeed({
    required String feedId,
    String? type,
    String? title,
    String? content,
    String? link,
    DateTime? eventDate,
    bool? isPinned,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (type != null) body['type'] = type;
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (link != null) body['link'] = link;
      if (eventDate != null) body['eventDate'] = eventDate.toIso8601String();
      if (isPinned != null) body['isPinned'] = isPinned;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiService.put(
        path: ApiEndpoints.feedById(feedId),
        body: body,
      );

      if (response.data['success'] == true) {
        final feed = FeedModel.fromJson(response.data['data']);

        // Update cached feed
        if (_cachedFeeds != null) {
          final index = _cachedFeeds!.indexWhere((f) => f.id == feedId);
          if (index != -1) {
            _cachedFeeds![index] = feed;
          }
        }

        return right(feed);
      } else {
        return left(response.data['message'] ?? 'Failed to update feed');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> deleteFeed(String feedId,
      {bool permanent = false}) async {
    try {
      final response = await _apiService.delete(
        path: ApiEndpoints.feedById(feedId),
        queryParameters: {'permanent': permanent.toString()},
      );

      if (response.data['success'] == true) {
        // Remove from cache
        _cachedFeeds?.removeWhere((f) => f.id == feedId);
        return right(unit);
      } else {
        return left(response.data['message'] ?? 'Failed to delete feed');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, FeedModel>> togglePinFeed(
      String feedId, bool isPinned) async {
    try {
      final response = await _apiService.patch(
        path: ApiEndpoints.togglePinFeed(feedId),
        body: {'isPinned': isPinned},
      );

      if (response.data['success'] == true) {
        final feed = FeedModel.fromJson(response.data['data']);

        // Update cached feed
        if (_cachedFeeds != null) {
          final index = _cachedFeeds!.indexWhere((f) => f.id == feedId);
          if (index != -1) {
            _cachedFeeds![index] = feed;
          }
        }

        return right(feed);
      } else {
        return left(response.data['message'] ?? 'Failed to pin/unpin feed');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, List<FeedModel>>> getUpcomingReminders(String classId,
      {int daysAhead = 7}) async {
    try {
      final response = await _apiService.get(
        path: ApiEndpoints.upcomingReminders(classId),
        queryParameters: {'daysAhead': daysAhead},
      );

      if (response.data['success'] == true) {
        final remindersList = (response.data['data'] as List)
            .map((e) => FeedModel.fromJson(e))
            .toList();
        return right(remindersList);
      } else {
        return left(response.data['message'] ?? 'Failed to fetch reminders');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, List<FeedModel>>> getMyCreatedFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'includeInactive': includeInactive.toString(),
      };
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        path: ApiEndpoints.myCreatedFeeds,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final feedsList = (response.data['data']['feeds'] as List)
            .map((e) => FeedModel.fromJson(e))
            .toList();
        return right(feedsList);
      } else {
        return left(
            response.data['message'] ?? 'Failed to fetch created feeds');
      }
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred: ${e.toString()}");
    }
  }

  void clearCache() {
    _cachedFeeds = null;
  }
}
