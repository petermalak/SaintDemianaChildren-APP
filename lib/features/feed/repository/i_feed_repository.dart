import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';

abstract class IFeedRepository {
  Future<Either<String, List<FeedModel>>> getMyFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
  });

  Future<Either<String, List<FeedModel>>> getFeedsByClass(
    String classId, {
    String? type,
    int limit = 50,
    int offset = 0,
    bool includeInactive = false,
  });

  Future<Either<String, FeedModel>> getFeedById(String feedId);

  Future<Either<String, FeedModel>> createFeed({
    required String classId,
    required String type,
    required String title,
    required String content,
    String? link,
    DateTime? eventDate,
    bool isPinned = false,
  });

  Future<Either<String, FeedModel>> updateFeed({
    required String feedId,
    String? type,
    String? title,
    String? content,
    String? link,
    DateTime? eventDate,
    bool? isPinned,
    bool? isActive,
  });

  Future<Either<String, Unit>> deleteFeed(String feedId,
      {bool permanent = false});

  Future<Either<String, FeedModel>> togglePinFeed(String feedId, bool isPinned);

  Future<Either<String, List<FeedModel>>> getUpcomingReminders(String classId,
      {int daysAhead = 7});

  Future<Either<String, List<FeedModel>>> getMyCreatedFeeds({
    String? type,
    int limit = 50,
    int offset = 0,
    bool includeInactive = false,
  });

  void clearCache();
}
