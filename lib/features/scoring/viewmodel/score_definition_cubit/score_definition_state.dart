import 'package:equatable/equatable.dart';

import '../../model/scoring_models.dart';

class ScoreDefinitionState extends Equatable {
  final List<ScoreDefinitionModel> definitions;
  final bool isLoading;
  final String? errorMessage;

  const ScoreDefinitionState({
    this.definitions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ScoreDefinitionState copyWith({
    List<ScoreDefinitionModel>? definitions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScoreDefinitionState(
      definitions: definitions ?? this.definitions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [definitions, isLoading, errorMessage];
}
