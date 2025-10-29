part of 'get_feed_cubit.dart';

sealed class GetFeedState {}

final class GetFeedInitial extends GetFeedState {}

final class GetFeedLoading extends GetFeedState {}

final class GetFeedLoadingMore extends GetFeedState {
  final List<FeedModel> feeds;
  GetFeedLoadingMore(this.feeds);
}

final class GetFeedSuccess extends GetFeedState {
  final List<FeedModel> feeds;
  final bool hasMore;
  GetFeedSuccess(this.feeds, {this.hasMore = false});
}

final class GetFeedFailure extends GetFeedState {
  final String errorMessage;
  GetFeedFailure(this.errorMessage);
}
