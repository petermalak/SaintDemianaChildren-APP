import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/feed_model.dart';
import '../../repository/i_feed_repository.dart';

part 'get_feed_state.dart';

class GetFeedCubit extends Cubit<GetFeedState> {
  GetFeedCubit(this._feedRepository) : super(GetFeedInitial());
  final IFeedRepository _feedRepository;

  Future<void> getMyFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset == 0) {
      emit(GetFeedLoading());
    } else {
      emit(GetFeedLoadingMore(
          state is GetFeedSuccess ? (state as GetFeedSuccess).feeds : []));
    }

    final response = await _feedRepository.getMyFeeds(
      type: type,
      limit: limit,
      offset: offset,
    );

    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (newFeeds) {
        if (offset == 0) {
          emit(GetFeedSuccess(newFeeds, hasMore: newFeeds.length >= limit));
        } else {
          final currentFeeds = state is GetFeedSuccess
              ? (state as GetFeedSuccess).feeds
              : <FeedModel>[];
          final allFeeds = [...currentFeeds, ...newFeeds];
          emit(GetFeedSuccess(allFeeds, hasMore: newFeeds.length >= limit));
        }
      },
    );
  }

  Future<void> getFeedsByClass(
    String classId, {
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset == 0) {
      emit(GetFeedLoading());
    } else {
      emit(GetFeedLoadingMore(
          state is GetFeedSuccess ? (state as GetFeedSuccess).feeds : []));
    }

    final response = await _feedRepository.getFeedsByClass(
      classId,
      type: type,
      limit: limit,
      offset: offset,
    );

    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (newFeeds) {
        if (offset == 0) {
          emit(GetFeedSuccess(newFeeds, hasMore: newFeeds.length >= limit));
        } else {
          final currentFeeds = state is GetFeedSuccess
              ? (state as GetFeedSuccess).feeds
              : <FeedModel>[];
          final allFeeds = [...currentFeeds, ...newFeeds];
          emit(GetFeedSuccess(allFeeds, hasMore: newFeeds.length >= limit));
        }
      },
    );
  }

  Future<void> getUpcomingReminders(String classId, {int daysAhead = 7}) async {
    emit(GetFeedLoading());
    final response = await _feedRepository.getUpcomingReminders(classId,
        daysAhead: daysAhead);
    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (reminders) => emit(GetFeedSuccess(reminders)),
    );
  }

  Future<void> getMyCreatedFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset == 0) {
      emit(GetFeedLoading());
    } else {
      emit(GetFeedLoadingMore(
          state is GetFeedSuccess ? (state as GetFeedSuccess).feeds : []));
    }

    final response = await _feedRepository.getMyCreatedFeeds(
      type: type,
      limit: limit,
      offset: offset,
    );

    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (newFeeds) {
        if (offset == 0) {
          emit(GetFeedSuccess(newFeeds, hasMore: newFeeds.length >= limit));
        } else {
          final currentFeeds = state is GetFeedSuccess
              ? (state as GetFeedSuccess).feeds
              : <FeedModel>[];
          final allFeeds = [...currentFeeds, ...newFeeds];
          emit(GetFeedSuccess(allFeeds, hasMore: newFeeds.length >= limit));
        }
      },
    );
  }

  Future<void> togglePinFeed(String feedId, bool isPinned) async {
    final response = await _feedRepository.togglePinFeed(feedId, isPinned);
    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (updatedFeed) {
        if (state is GetFeedSuccess) {
          final currentFeeds = (state as GetFeedSuccess).feeds;
          final updatedFeeds = currentFeeds.map((feed) {
            return feed.id == feedId ? updatedFeed : feed;
          }).toList();

          // Sort to move pinned feeds to top
          updatedFeeds.sort((a, b) {
            if (a.isPinned == b.isPinned) {
              return (b.createdAt ?? DateTime.now())
                  .compareTo(a.createdAt ?? DateTime.now());
            }
            return (b.isPinned ?? false) ? 1 : -1;
          });

          emit(GetFeedSuccess(updatedFeeds,
              hasMore: (state as GetFeedSuccess).hasMore));
        }
      },
    );
  }

  Future<void> deleteFeed(String feedId, {bool permanent = false}) async {
    final response =
        await _feedRepository.deleteFeed(feedId, permanent: permanent);
    response.fold(
      (failure) => emit(GetFeedFailure(failure)),
      (_) {
        if (state is GetFeedSuccess) {
          final currentFeeds = (state as GetFeedSuccess).feeds;
          final updatedFeeds =
              currentFeeds.where((feed) => feed.id != feedId).toList();
          emit(GetFeedSuccess(updatedFeeds,
              hasMore: (state as GetFeedSuccess).hasMore));
        }
      },
    );
  }

  void clearFeeds() {
    _feedRepository.clearCache();
    emit(GetFeedInitial());
  }
}
