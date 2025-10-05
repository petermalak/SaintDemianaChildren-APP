import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/feed/view/widget/feed_card.dart';
import 'package:saint_demiana_children/features/feed/viewmodel/get_feed/get_feed_cubit.dart';

import '../../../../core/di/service_locator.dart';
import '../../repository/i_feed_repository.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocProvider(
        create: (context) => GetFeedCubit(
          sl<IFeedRepository>(),
        )..getFeeds(),
        child: BlocBuilder<GetFeedCubit, GetFeedState>(
          builder: (context, state) {
            if (state is GetFeedLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GetFeedFailure) {
              return Center(child: Text(state.errorMessage));
            } else if (state is GetFeedSuccess) {
              final feeds = state.feeds;
              if (feeds.isEmpty) {
                return const Center(child: Text('No feeds available'));
              }
              return ListView.separated(
                itemBuilder: (context, index) {
                  return FeedCard(feed: feeds[index]);
                },
                separatorBuilder: (_, __) => const SizedBox(
                  height: 10,
                ),
                itemCount: feeds.length,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
