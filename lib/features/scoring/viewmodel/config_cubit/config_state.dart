import 'package:equatable/equatable.dart';
import '../../model/scoring_models.dart';

abstract class ConfigState extends Equatable {
  const ConfigState();

  @override
  List<Object?> get props => [];
}

class ConfigInitial extends ConfigState {}

class ConfigLoading extends ConfigState {}

class ConfigLoaded extends ConfigState {
  final ScoringConfigModel config;

  const ConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

class TiersLoaded extends ConfigState {
  final List<ScoringTierModel> tiers;

  const TiersLoaded(this.tiers);

  @override
  List<Object?> get props => [tiers];
}

class ConfigUpdated extends ConfigState {
  final ScoringConfigModel config;

  const ConfigUpdated(this.config);

  @override
  List<Object?> get props => [config];
}

class TierCreated extends ConfigState {
  final ScoringTierModel tier;

  const TierCreated(this.tier);

  @override
  List<Object?> get props => [tier];
}

class TierUpdated extends ConfigState {
  final ScoringTierModel tier;

  const TierUpdated(this.tier);

  @override
  List<Object?> get props => [tier];
}

class TierDeleted extends ConfigState {
  const TierDeleted();
}

class ConfigError extends ConfigState {
  final String message;

  const ConfigError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConfigSuccess extends ConfigState {
  final String message;

  const ConfigSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
