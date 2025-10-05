import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';
import 'package:saint_demiana_children/features/feed/repository/i_feed_repository.dart';

part 'add_feed_state.dart';

class AddFeedCubit extends Cubit<AddFeedState> {
  AddFeedCubit(this._feedRepository) : super(AddFeedInitial());
  final IFeedRepository _feedRepository;

  Future<void> addFeed(FeedModel feed) async {
    emit(AddFeedLoading());
    final response = await _feedRepository.addFeed(feed);
    response.fold((failure) => emit(AddFeedFailure(failure)),
        (success) => emit(AddFeedSuccess()));
  }
}
