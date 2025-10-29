import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';
import 'package:saint_demiana_children/features/feed/repository/i_feed_repository.dart';

part 'add_feed_state.dart';

class AddFeedCubit extends Cubit<AddFeedState> {
  AddFeedCubit(this._feedRepository) : super(AddFeedInitial());
  final IFeedRepository _feedRepository;

  Future<void> createFeed({
    required String classId,
    required String type,
    required String title,
    required String content,
    String? link,
    DateTime? eventDate,
    bool isPinned = false,
  }) async {
    emit(AddFeedLoading());

    final response = await _feedRepository.createFeed(
      classId: classId,
      type: type,
      title: title,
      content: content,
      link: link,
      eventDate: eventDate,
      isPinned: isPinned,
    );

    response.fold(
      (failure) => emit(AddFeedFailure(failure)),
      (feed) => emit(AddFeedSuccess(feed)),
    );
  }

  Future<void> updateFeed({
    required String feedId,
    String? type,
    String? title,
    String? content,
    String? link,
    DateTime? eventDate,
    bool? isPinned,
    bool? isActive,
  }) async {
    emit(AddFeedLoading());

    final response = await _feedRepository.updateFeed(
      feedId: feedId,
      type: type,
      title: title,
      content: content,
      link: link,
      eventDate: eventDate,
      isPinned: isPinned,
      isActive: isActive,
    );

    response.fold(
      (failure) => emit(AddFeedFailure(failure)),
      (feed) => emit(AddFeedSuccess(feed)),
    );
  }

  void reset() {
    emit(AddFeedInitial());
  }
}
