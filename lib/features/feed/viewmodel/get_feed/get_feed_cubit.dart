import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/feed_model.dart';
import '../../repository/i_feed_repository.dart';

part 'get_feed_state.dart';

class GetFeedCubit extends Cubit<GetFeedState> {
  GetFeedCubit(this._feedRepository) : super(GetFeedInitial());
  final IFeedRepository _feedRepository;

  Future<void> getFeeds() async {
    emit(GetFeedLoading());
    final response = await _feedRepository.getFeed();
    response.fold((failure) => emit(GetFeedFailure(failure)),
        (success) => emit(GetFeedSuccess(success)));
  }
}
