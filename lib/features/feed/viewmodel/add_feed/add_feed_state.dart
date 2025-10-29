part of 'add_feed_cubit.dart';

sealed class AddFeedState {}

final class AddFeedInitial extends AddFeedState {}

final class AddFeedLoading extends AddFeedState {}

final class AddFeedSuccess extends AddFeedState {
  final FeedModel feed;
  AddFeedSuccess(this.feed);
}

final class AddFeedFailure extends AddFeedState {
  final String errorMessage;
  AddFeedFailure(this.errorMessage);
}
