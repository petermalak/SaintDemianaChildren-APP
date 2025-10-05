part of 'add_feed_cubit.dart';

@immutable
sealed class AddFeedState {}

final class AddFeedInitial extends AddFeedState {}

final class AddFeedLoading extends AddFeedState {}

final class AddFeedSuccess extends AddFeedState {}

final class AddFeedFailure extends AddFeedState {
  final String errorMessage;
  AddFeedFailure(this.errorMessage);
}
