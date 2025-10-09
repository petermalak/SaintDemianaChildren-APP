import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';

import 'package:saint_demiana_children/features/feed/model/feed_model.dart';

import '../../../core/services/interface/i_api_service.dart';
import 'i_feed_repository.dart';

class FeedRepository implements IFeedRepository {
  final IApiService _apiService;
  FeedRepository(this._apiService);
  List<FeedModel>? feeds;

  @override
  Future<Either<String, List<FeedModel>>> getFeed() async {
    try {
      if (feeds != null) {
        return right(feeds!);
      }
      return await _fetchFeeds();
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  Future<Either<String, List<FeedModel>>> _fetchFeeds() async {
    try {
      final response = await _apiService.get(path: ApiEndpoints.feed);
      feeds = response.data.map((e) => FeedModel.fromJson(e)).toList();
      // feeds=[
      //   FeedModel(
      //     id: "1",
      //     title: "Feed Title 1",
      //     description: "This is the description for feed 1.",
      //     imageUrl: "https://th.bing.com/th/id/R.f5562edaf787849bebffee610e80f713?rik=kv3bduJl8kmnWg&pid=ImgRaw&r=0",
      //     date: DateTime.now().subtract(const Duration(days: 1)),
      //   ),
      //   FeedModel(
      //     id: "2",
      //     title: "Feed Title 2",
      //     description: "This is the description for feed 2.",
      //     date: DateTime.now().subtract(const Duration(days: 2)),
      //   ),
      //   FeedModel(
      //     id: "3",
      //     title: "Feed Title 3",
      //     description: "This is the description for feed 3.",
      //     date: DateTime.now().subtract(const Duration(days: 3)),
      //   ),
      // ];
      return right(feeds!);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }

  @override
  Future<Either<String, Unit>> addFeed(FeedModel feed) async {
    try {
      final response =
          await _apiService.post(path: ApiEndpoints.feed, body: feed.toJson());
      feeds?.add(FeedModel.fromJson(response.data));
      return right(unit);
    } on DioException catch (e) {
      return left(_apiService.handleError(e));
    } catch (e) {
      return left("An unexpected error occurred");
    }
  }
}
