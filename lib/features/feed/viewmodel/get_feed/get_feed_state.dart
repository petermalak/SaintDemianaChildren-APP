part of 'get_feed_cubit.dart';

@immutable
sealed class GetFeedState {}

final class GetFeedInitial extends GetFeedState {}

final class GetFeedLoading extends GetFeedState {}

final class GetFeedSuccess extends GetFeedState {
  final List<FeedModel> feeds;
  GetFeedSuccess(this.feeds);
}

final class GetFeedFailure extends GetFeedState {
  final String errorMessage;
  GetFeedFailure(this.errorMessage);
}
