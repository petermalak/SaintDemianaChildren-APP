import 'package:equatable/equatable.dart';
import '../../model/scoring_models.dart';

abstract class ScoringState extends Equatable {
  const ScoringState();

  @override
  List<Object?> get props => [];
}

// User Score States
class ScoringInitial extends ScoringState {}

class ScoringLoading extends ScoringState {}

class UserScoreLoaded extends ScoringState {
  final UserScoreModel userScore;

  const UserScoreLoaded(this.userScore);

  @override
  List<Object?> get props => [userScore];
}

class MyScoresLoaded extends ScoringState {
  final List<UserScoreModel> scores;

  const MyScoresLoaded(this.scores);

  @override
  List<Object?> get props => [scores];
}

class LeaderboardLoaded extends ScoringState {
  final List<LeaderboardEntryModel> leaderboard;

  const LeaderboardLoaded(this.leaderboard);

  @override
  List<Object?> get props => [leaderboard];
}

class TransactionsLoaded extends ScoringState {
  final List<ScoreTransactionModel> transactions;

  const TransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class UserRankLoaded extends ScoringState {
  final int rank;
  final int totalPoints;
  final ScoringTierModel? tier;

  const UserRankLoaded({
    required this.rank,
    required this.totalPoints,
    this.tier,
  });

  @override
  List<Object?> get props => [rank, totalPoints, tier];
}

class StatsLoaded extends ScoringState {
  final ScoreStats stats;

  const StatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class PointsUpdated extends ScoringState {
  final int oldPoints;
  final int newPoints;
  final bool wasAddition;

  const PointsUpdated({
    required this.oldPoints,
    required this.newPoints,
    required this.wasAddition,
  });

  @override
  List<Object?> get props => [oldPoints, newPoints, wasAddition];
}

class ScoringError extends ScoringState {
  final String message;

  const ScoringError(this.message);

  @override
  List<Object?> get props => [message];
}

class ScoringSuccess extends ScoringState {
  final String message;

  const ScoringSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
