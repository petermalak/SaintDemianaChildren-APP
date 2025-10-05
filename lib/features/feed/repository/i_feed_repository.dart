import 'package:dartz/dartz.dart';
import 'package:saint_demiana_children/features/feed/model/feed_model.dart';

abstract class IFeedRepository {
  Future<Either<String, List<FeedModel>>> getFeed();
  Future<Either<String, Unit>> addFeed(FeedModel feed);
}
